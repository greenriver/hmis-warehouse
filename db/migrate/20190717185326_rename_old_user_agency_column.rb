class RenameOldUserAgencyColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :agency, :deprecated_agency
  end
end
