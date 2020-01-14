class RemoveUnusedRank < ActiveRecord::Migration[4.2]
  def change
    remove_column :claims_ed_nyu_severity, :rank, :integer
  end
end
