class Add2022SpecItems < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :Female, :integer
    add_column :Client, :Male, :integer
    add_column :Client, :GenderOther, :integer
    add_column :Client, :Transgender, :integer
    add_column :Client, :Questioning, :integer
    add_column :Client, :GenderNone, :integer

    add_column :Disabilities, :AntiRetroviral, :integer

    # This are new names for existing columns, but we will keep the old columns for a while
    add_column :Enrollment, :MentalHealthDisorderFam, :integer
    add_column :Enrollment, :AlcoholDrugUseDisorderFam, :integer

    add_column :Enrollment, :ClientLeaseholder, :integer
    add_column :Enrollment, :HOHLeasesholder, :integer
    add_column :Enrollment, :IncarceratedAdult, :integer
    add_column :Enrollment, :PrisonDischarge, :integer
    add_column :Enrollment, :CurrentPregnant, :integer
    add_column :Enrollment, :CoCPrioritized, :integer
    add_column :Enrollment, :TargetScreenReqd, :integer

    add_column :Export, :CSVVersion, :string

    add_column :HealthAndDV, :LifeValue, :integer
    add_column :HealthAndDV, :SupportfromOthers, :integer
    add_column :HealthAndDV, :BounceBack, :integer
    add_column :HealthAndDV, :FeelingFrequency, :integer

    add_column :IncomeBenefits, :RyanWhiteMedDent, :integer
    add_column :IncomeBenefits, :NoRyanWhiteReason, :integer

    # New name for existing column
    add_column :Organization, :VictimServiceProvider, :integer

    add_column :Project, :HOPWAMedAssistedLivingFac, :integer

    add_column :Services, :MovingOnOtherType, :string

    create_table :YouthEducationStatus do |t|
      t.string :YouthEducationStatusID, limit: 32, null: false
      t.string :EnrollmentID, limit: 32, null: false
      t.string :PersonalID, limit: 32, null: false
      t.date :InformationDate, null: false
      t.integer :CurrentSchoolAttend
      t.integer :MostRecentEdStatus
      t.integer :CurrentEdStatus
      t.integer :DataCollectionStage, null: false
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.string :UserID, limit: 32, null: false
      t.datetime :DateDeleted
      t.string :ExportID, limit: 32, null: false
      t.integer :data_source_id
    end

    add_index :YouthEducationStatus, [:YouthEducationStatusID, :data_source_id], name: :youth_ed_ev_id_ds_id
    add_index :YouthEducationStatus, [:YouthEducationStatusID, :EnrollmentID, :PersonalID, :data_source_id], name: :youth_eds_id_e_id_p_id_ds_id
  end
end
