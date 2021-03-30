class CreateFunctionTest < ActiveRecord::Migration[6.1]
  def change
    create_function :test
  end
end
