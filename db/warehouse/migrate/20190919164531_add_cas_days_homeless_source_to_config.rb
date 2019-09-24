class AddCasDaysHomelessSourceToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :cas_days_homeless_source, :string, default: :days_homeless
  end
end
