class RenamePatientField < ActiveRecord::Migration[4.2][4.2]
  def change
    rename_column :patients, :import_pk, :id_in_source
    add_column :patients, :client_id, :integer, index: true
  end
end
