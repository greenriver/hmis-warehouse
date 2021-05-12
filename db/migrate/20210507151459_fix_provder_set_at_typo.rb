class FixProvderSetAtTypo < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :provder_set_at, :provider_set_at
  end
end
