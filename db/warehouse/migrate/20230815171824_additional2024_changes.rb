class Additional2024Changes < ActiveRecord::Migration[6.1]
  def change
    create_table :CEParticipation do |t|
      t.string :CEParticipationID, null: false, index: true
      t.string :ProjectID, null: false, index: true
      t.integer :AccessPoint, null: false
      t.integer :PreventionAssessment
      t.integer :CrisisAssessment
      t.integer :HousingAssessment
      t.integer :DirectServices
      t.integer :ReceivesReferrals
      t.date :CEParticipationStatusStartDate, null: false
      t.date :CEParticipationStatusEndDate, null: true
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
      t.string :UserID, null: false
      t.string :ExportID, null: false
      t.integer :data_source_id
    end

    add_column :IncomeBenefits, :VHAServices, :integer
    add_column :IncomeBenefits, :NoVHAServices, :integer
  end
end
