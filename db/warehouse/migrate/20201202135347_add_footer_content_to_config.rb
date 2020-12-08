class AddFooterContentToConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :support_contact_email, :string
  end
end
