class Add2024Columns < ActiveRecord::Migration[6.1]
  def change
    # Project
    add_column :Project, :RRHSubType, :integer, null: true

    # Client
    # races
    add_column :Client, :HispanicLatinaeo, :integer, null: true
    add_column :Client, :MidEastNAfrican, :integer, null: true
    add_column :Client, :AdditionalRaceEthnicity, :string, null: true
    # genders
    add_column :Client, :Woman, :integer, null: true # rename Female
    add_column :Client, :Man, :integer, null: true # rename Male
    add_column :Client, :NonBinary, :integer, null: true # rename NoSingleGender
    add_column :Client, :CulturallySpecific, :integer, null: true
    add_column :Client, :DifferentIdentity, :integer, null: true
    add_column :Client, :DifferentIdentityText, :string, null: true

    # Enrollment
    add_column :Enrollment, :EnrollmentCoC, :string, null: true # limit? non-nullable!
    add_column :Enrollment, :RentalSubsidyType, :integer, null: true
    # c4
    add_column :Enrollment, :TranslationNeeded, :integer, null: true
    add_column :Enrollment, :PreferredLanguage, :integer, null: true
    add_column :Enrollment, :PreferredLanguageDifferent, :string, null: true

    # Exit
    add_column :Exit, :DestinationSubsidyType, :integer, null: true

    # HealthAndDV
    add_column :HealthAndDV, :DomesticViolenceSurvivor, :integer, null: true # rename DomesticViolenceVictim

    # Services
    # None, V3 fields already added in previous migration

    # CurrentLivingSituation
    add_column :CurrentLivingSituation, :CLSSubsidyType, :integer, null: true
  end
end
