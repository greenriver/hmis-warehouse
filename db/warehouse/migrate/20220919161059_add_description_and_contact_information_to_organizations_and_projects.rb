class AddDescriptionAndContactInformationToOrganizationsAndProjects < ActiveRecord::Migration[6.1]
  def change
    [
      :Organization,
      :Project,
    ].each do |table_name|
      add_column table_name, :description, :string
      add_column table_name, :contact_information, :string
    end
  end
end
