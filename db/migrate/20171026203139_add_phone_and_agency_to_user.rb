class AddPhoneAndAgencyToUser < ActiveRecord::Migration
  def change
    add_column :users, :phone, :string
    add_column :users, :agency, :string
  end
end
