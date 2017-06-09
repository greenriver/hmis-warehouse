class RenamePatientField < ActiveRecord::Migration
  def change
    rename_column :patients, :import_pk, :id_in_source
    add_column :patients, :client_id, :integer, index: true
  end
end
