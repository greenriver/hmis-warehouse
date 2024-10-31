class RemoveCurrentLivingSituationVerifiedByLimit2 < ActiveRecord::Migration[7.0]
  # The view 'bi_CurrentLivingSituation' depends on column 'VerifiedBy' we are modifying. We need to remove it before making this change and recreate it afterwards.
  # Running into locking issues when running the steps in the same migration so splitting them out into individual migrations
  # 1. Drop the view
  # 2. Modify the column size
  # 3. Recreate the view
  def up
    change_column :CurrentLivingSituation, :VerifiedBy, :string, limit: nil
  end

  def down
    # Including the revese steps for rollbacks
    change_column :CurrentLivingSituation, :VerifiedBy, :string, limit: 100
  end
end
