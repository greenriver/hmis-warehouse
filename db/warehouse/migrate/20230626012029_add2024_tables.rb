class Add2024Tables < ActiveRecord::Migration[6.1]
  def change
    create_table :HMISParticipation do |t|
      t.string :HMISParticipationID, null: false, index: true
      t.string :ProjectID, null: false, index: true
      t.integer :HMISParticipationType, null: false # make nullable in db?
      t.date :HMISParticipationStatusStartDate, null: false # make nullable in db?
      t.date :HMISParticipationStatusEndDate, null: true
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
      t.string :UserID, null: false
      t.string :ExportID, null: false
      t.integer :data_source_id
    end

    # Not yet created: new CEParticipation table
    # Not yet created: CEActivity table
  end
end
