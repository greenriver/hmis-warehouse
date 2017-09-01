class RemoveUnusedRank < ActiveRecord::Migration
  def change
    remove_column :claims_ed_nyu_severity, :rank, :integer
  end
end
