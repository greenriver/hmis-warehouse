class AddZipPassword < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_hmis_exports, :encrypted_zip_password, :string
    add_column :recurring_hmis_exports, :encrypted_zip_password_iv, :string
  end
end
