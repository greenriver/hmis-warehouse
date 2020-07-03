class AddInvestigatorToContactsAndSiteLeaders < ActiveRecord::Migration[5.2]
  def change
    add_column :tracing_staffs, :investigator, :string
    add_column :tracing_site_leaders, :investigator, :string
  end
end
