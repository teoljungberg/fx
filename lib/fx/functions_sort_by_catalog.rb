require "tsort"

module Fx
  class FunctionsSortByCatalog
    include TSort

    def self.call(functions)
      new(functions).call
    end

    def initialize(functions)
      @functions = functions
    end

    def call
      @dependencies = fetch_dependencies

      # Uses strongly_connected_components instead of tsort to tolerate
      # mutually recursive functions, which are valid in PostgreSQL.
      strongly_connected_components.flatten(FLATTEN_DEPTH)
    end

    private

    FLATTEN_DEPTH = 1
    private_constant :FLATTEN_DEPTH

    # Queries pg_depend for function-to-function dependencies, returning
    # full signatures so overloaded functions are correctly distinguished.
    #
    # PostgreSQL only records pg_depend entries for SQL-language functions
    # that use BEGIN ATOMIC bodies (PostgreSQL 14+). Traditional
    # string-literal bodies (AS $$ ... $$) are not parsed at definition
    # time, so their cross-function calls are invisible to pg_depend --
    # regardless of language. Use FunctionsSortByDefinition (regex-based)
    # for those.
    DEPENDENCY_QUERY = <<~SQL.freeze
      SELECT DISTINCT
          dep_proc.proname || '(' || pg_get_function_identity_arguments(dep_proc.oid) || ')' AS dependent,
          ref_proc.proname || '(' || pg_get_function_identity_arguments(ref_proc.oid) || ')' AS dependency
      FROM pg_depend pd
      JOIN pg_proc dep_proc
          ON dep_proc.oid = pd.objid
      JOIN pg_proc ref_proc
          ON ref_proc.oid = pd.refobjid
      JOIN pg_namespace dep_ns
          ON dep_ns.oid = dep_proc.pronamespace
      JOIN pg_namespace ref_ns
          ON ref_ns.oid = ref_proc.pronamespace
      WHERE pd.classid = 'pg_proc'::regclass
          AND pd.refclassid = 'pg_proc'::regclass
          AND pd.deptype = 'n'
          AND dep_ns.nspname = ANY (current_schemas(false))
          AND ref_ns.nspname = ANY (current_schemas(false))
    SQL
    private_constant :DEPENDENCY_QUERY

    attr_reader :functions, :dependencies

    def tsort_each_node(&block)
      functions.each(&block)
    end

    def tsort_each_child(function, &block)
      deps = dependencies.fetch(function.signature, [])
      functions.select { |f| deps.include?(f.signature) }.each(&block)
    end

    def fetch_dependencies
      return {} if functions.empty?

      signatures = functions.map(&:signature).to_set
      rows = connection.exec_query(DEPENDENCY_QUERY)
      rows.each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, hash|
        dependent = row["dependent"]
        dependency = row["dependency"]

        if signatures.include?(dependent) && signatures.include?(dependency)
          hash[dependent] << dependency
        end
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
