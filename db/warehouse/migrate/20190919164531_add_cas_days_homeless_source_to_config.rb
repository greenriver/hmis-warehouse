class AddCasDaysHomelessSourceToConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :cas_days_homeless_source, :string, default: :days_homeless
  end
end
