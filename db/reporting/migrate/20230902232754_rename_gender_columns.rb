class RenameGenderColumns < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:rename_column)

    rename_column :warehouse_houseds, :non_binary, :nonbinary
    rename_column :warehouse_houseds, :culturally_specific, :culturallyspecific
    rename_column :warehouse_houseds, :different_identity, :differentidentity

    rename_column :warehouse_returns, :non_binary, :nonbinary
    rename_column :warehouse_returns, :culturally_specific, :culturallyspecific
    rename_column :warehouse_returns, :different_identity, :differentidentity
  ensure
    StrongMigrations.enable_check(:rename_column)
  end
end
