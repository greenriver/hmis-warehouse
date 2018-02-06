class IndexServicesOnProjectEntryId < ActiveRecord::Migration
  def change
    add_index :Services, [:ProjectEntryID, :PersonalID]
  end
end
