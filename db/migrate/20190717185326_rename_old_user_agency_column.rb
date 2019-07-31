class RenameOldUserAgencyColumn < ActiveRecord::Migration
  def change
    rename_column :users, :agency, :deprecated_agency
  end
end
