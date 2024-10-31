class RemoveCurrentLivingSituationVerifiedByLimit3 < ActiveRecord::Migration[7.0]
  # The view 'bi_CurrentLivingSituation' depends on column 'VerifiedBy' we are modifying. We need to remove it before making this change and recreate it afterwards.
  # Running into locking issues when running the steps in the same migration so splitting them out into individual migrations
  # 1. Drop the view
  # 2. Modify the column size
  # 3. Recreate the view
  def up
    Bi::ViewMaintainer.new.safe_create_role
    Bi::ViewMaintainer.new.non_client_view(GrdaWarehouse::Hud::CurrentLivingSituation)
  end

  def down
    # Including the revese steps for rollbacks
    safety_assured do
      Bi::ViewMaintainer.new.safe_drop_view(Bi::ViewMaintainer.new.view_name(GrdaWarehouse::Hud::CurrentLivingSituation))
    end
  end
end
