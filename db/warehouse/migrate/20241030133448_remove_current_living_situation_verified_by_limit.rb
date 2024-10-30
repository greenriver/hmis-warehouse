class RemoveCurrentLivingSituationVerifiedByLimit < ActiveRecord::Migration[7.0]
  def change
    # view 'bi_CurrentLivingSituation' depends on column 'VerifiedBy'. Need to remove it before making this change and recreate it afterwards.
    safety_assured do
      drop_view 'bi_CurrentLivingSituation', revert_to_version: 1
      reversible do |dir|
        dir.up do
          change_column :CurrentLivingSituation, :VerifiedBy, :string, :limit => nil
        end
        dir.down do
          change_column :CurrentLivingSituation, :VerifiedBy, :string, :limit => 100
        end
      end
      create_view 'bi_CurrentLivingSituation'
    end
  end
end
