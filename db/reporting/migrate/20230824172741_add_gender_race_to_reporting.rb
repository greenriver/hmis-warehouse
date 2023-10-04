class AddGenderRaceToReporting < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_houseds, :woman, :integer
    add_column :warehouse_houseds, :man, :integer
    add_column :warehouse_houseds, :non_binary, :integer
    add_column :warehouse_houseds, :culturally_specific, :integer
    add_column :warehouse_houseds, :different_identity, :integer

    add_column :warehouse_returns, :woman, :integer
    add_column :warehouse_returns, :man, :integer
    add_column :warehouse_returns, :non_binary, :integer
    add_column :warehouse_returns, :culturally_specific, :integer
    add_column :warehouse_returns, :different_identity, :integer
  end
end
