class AddHmisCaseNotes < ActiveRecord::Migration[6.1]
  def change
    create_table(:CustomCaseNote) do |t|
      t.string :CustomCaseNoteID, null: false
      t.string :PersonalID, null: false, index: true
      t.string :EnrollmentID, index: true
      t.references :data_source, null: false, index: false
      t.text :content, null: false
      t.string :UserID, index: true
      t.date :DateCreated
      t.date :DateUpdated
      t.date :DateDeleted
      t.index [:data_source_id, :CustomCaseNoteID], unique: true, name: 'idxCustomCaseNoteOnID'
    end
  end
end
