class AddDescriptionAndContactInformationToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :Organization, :description, :string
    add_column :Organization, :contact_information, :string
  end
end
