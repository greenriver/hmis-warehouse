class RenameHmisFormResponse < ActiveRecord::Migration[4.2]
  def change
    rename_column :hmis_forms, :response, :api_response
  end
end
