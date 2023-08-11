class Add2024Columns < ActiveRecord::Migration[6.1]
  def change
    # Project
    add_column :Project, :RRHSubType, :integer

    # Client
    # races
    add_column :Client, :HispanicLatinaeo, :integer
    add_column :Client, :MidEastNAfrican, :integer
    add_column :Client, :AdditionalRaceEthnicity, :string
    # genders
    add_column :Client, :Woman, :integer # rename Female
    add_column :Client, :Man, :integer # rename Male
    add_column :Client, :NonBinary, :integer # rename NoSingleGender
    add_column :Client, :CulturallySpecific, :integer
    add_column :Client, :DifferentIdentity, :integer
    add_column :Client, :DifferentIdentityText, :string

    # Enrollment
    add_column :Enrollment, :EnrollmentCoC, :string
    add_column :Enrollment, :RentalSubsidyType, :integer
    # c4
    add_column :Enrollment, :TranslationNeeded, :integer
    add_column :Enrollment, :PreferredLanguage, :integer
    add_column :Enrollment, :PreferredLanguageDifferent, :string

    # Exit
    add_column :Exit, :DestinationSubsidyType, :integer

    # HealthAndDV
    add_column :HealthAndDV, :DomesticViolenceSurvivor, :integer # rename DomesticViolenceVictim

    # Services
    # None, V3 fields already added in previous migration

    # CurrentLivingSituation
    add_column :CurrentLivingSituation, :CLSSubsidyType, :integer
  end
end
