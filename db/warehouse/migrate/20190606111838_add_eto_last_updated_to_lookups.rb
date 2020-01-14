class AddEtoLastUpdatedToLookups < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :eto_last_updated, :datetime
    add_column :hmis_forms, :eto_last_updated, :datetime
  end
end
