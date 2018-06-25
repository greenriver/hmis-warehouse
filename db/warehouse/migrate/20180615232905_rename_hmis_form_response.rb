class RenameHmisFormResponse < ActiveRecord::Migration
  def change
    rename_column :hmis_forms, :response, :api_response
  end
end
