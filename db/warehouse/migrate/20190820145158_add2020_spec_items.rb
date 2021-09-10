class Add2020SpecItems < ActiveRecord::Migration[4.2]
  def change
    add_column :Organization, :VictimServicesProvider, :integer

    create_table :User do |t|
      t.string :UserID, null: false, limit: 32
      t.string :UserFirstName
      t.string :UserLastName
      t.string :UserPhone, limit: 10
      t.string :UserExtension, limit: 5
      t.string :UserEmail
      t.datetime :DateCreated
      t.datetime :DateUpdated
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :User, [:UserID, :data_source_id]

    add_column :Project, :HMISParticipatingProject, :integer

    add_column :Funder, :OtherFunder, :string

    add_column :ProjectCoC, :Geocode, :string, limit: 6
    add_column :ProjectCoC, :GeographyType, :integer
    add_column :ProjectCoC, :Address1, :string
    add_column :ProjectCoC, :Address2, :string
    add_column :ProjectCoC, :City, :string
    add_column :ProjectCoC, :State, :string, limit: 2
    add_column :ProjectCoC, :Zip, :string, limit: 5

    add_column :Inventory, :CHVetBedInventory, :integer
    add_column :Inventory, :YouthVetBedInventory, :integer
    add_column :Inventory, :CHYouthBedInventory, :integer
    add_column :Inventory, :OtherBedInventory, :integer
    add_column :Inventory, :TargetPopulation, :integer
    add_column :Inventory, :ESBedType, :integer

    add_column :Enrollment, :SexualOrientationOther, :string, limit: 100


    create_table :CurrentLivingSituation do |t|
      t.string :CurrentLivingSitID, limit: 32, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.date :InformationDate, null: false
      t.integer :CurrentLivingSituation, null: false
      t.string :VerifiedBy
      t.integer :LeaveSituation14Days
      t.integer :SubsequentResidence
      t.integer :ResourcesToObtain
      t.integer :LeaseOwn60Day
      t.integer :MovedTwoOrMore
      t.string :LocationDetails
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :CurrentLivingSituation, [:CurrentLivingSitID, :data_source_id], name: :cur_liv_sit_cur_id_ds_id
    add_index :CurrentLivingSituation, [:PersonalID, :EnrollmentID, :data_source_id, :CurrentLivingSitID], name: :cur_liv_sit_p_id_en_id_ds_id_cur_id

    create_table :Assessment do |t|
      t.string :AssessmentID, limit: 32, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.date :AssessmentDate, null: false
      t.string :AssessmentLocation, null: false
      t.integer :AssessmentType, null: false
      t.integer :AssessmentLevel, null: false
      t.integer :PrioritizationStatus, null: false
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :Assessment, [:AssessmentID, :data_source_id], name: :assessment_a_id_ds_id
    add_index :Assessment, [:PersonalID, :EnrollmentID, :data_source_id, :AssessmentID], name: :assessment_p_id_en_id_ds_id_a_id

    create_table :AssessmentQuestions do |t|
      t.string :AssessmentQuestionID, limit: 32, null: false
      t.string :AssessmentID, limit: 32, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.string :AssessmentQuestionGroup
      t.integer :AssessmentQuestionOrder
      t.string :AssessmentQuestion
      t.string :AssessmentAnswer
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :AssessmentQuestions, [:AssessmentQuestionID, :data_source_id], name: :assessment_q_aq_id_ds_id
    add_index :AssessmentQuestions, [:AssessmentID, :data_source_id, :PersonalID, :EnrollmentID, :AssessmentQuestionID], name: :assessment_q_a_id_ds_id_p_id_en_id_aq_id

    create_table :AssessmentResults do |t|
      t.string :AssessmentResultID, limit: 32, null: false
      t.string :AssessmentID, limit: 32, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.string :AssessmentResultType
      t.string :AssessmentResult
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :AssessmentResults, [:AssessmentResultID, :data_source_id], name: :assessment_r_ar_id_ds_id
    add_index :AssessmentResults, [:AssessmentID, :data_source_id, :PersonalID, :EnrollmentID, :AssessmentResultID], name: :assessment_r_a_id_ds_id_p_id_en_id_ar_id

    create_table :Event do |t|
      t.string :EventID, limit: 32, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.date :EventDate, null: false
      t.integer :Event, null: false
      t.integer :ProbSolDivRRResult
      t.integer :ReferralCaseManageAfter
      t.string :LocationCrisisOrPHHousing
      t.integer :ReferralResult
      t.date :ResultDate
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID
      t.integer :data_source_id
    end

    add_index :Event, [:EventID, :data_source_id], name: :event_ev_id_ds_id
    add_index :Event, [:data_source_id, :PersonalID, :EnrollmentID, :EventID], name: :event_ds_id_p_id_en_id_ev_id
  end
end
