class RenamedVamcColumns < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      rename_column :Enrollment, :VAMCStation, :VAMCStation_deleted
      rename_column :Enrollment, :VAMCStation_new, :VAMCStation
    }
  end
end
