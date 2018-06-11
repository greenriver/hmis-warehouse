class AddShortNameToAcOs < ActiveRecord::Migration
  def change
    add_column :accountable_care_organizations, :short_name, :string
    add_column :accountable_care_organizations, :mco_pid, :integer
    add_column :accountable_care_organizations, :mco_sl, :string
    add_column :accountable_care_organizations, :active, :boolean, default: true, null: false

  end
end
