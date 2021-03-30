class UpdateFunctionTestToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_function :test, version: 2, revert_to_version: 1
  end
end
