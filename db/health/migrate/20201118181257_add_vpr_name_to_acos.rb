class AddVprNameToAcos < ActiveRecord::Migration[5.2]
  def change
    add_column :accountable_care_organizations, :vpr_name, :string
  end
end
