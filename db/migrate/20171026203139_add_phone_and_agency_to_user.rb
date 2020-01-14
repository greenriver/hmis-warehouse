class AddPhoneAndAgencyToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :phone, :string
    add_column :users, :agency, :string
  end
end
