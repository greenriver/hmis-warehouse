class Add2024FieldsToAggregatedEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_aggregated_enrollments, :EnrollmentCoC, :string
    add_column :hmis_aggregated_enrollments, :RentalSubsidyType, :integer

    add_column :hmis_aggregated_enrollments, :TranslationNeeded, :integer
    add_column :hmis_aggregated_enrollments, :PreferredLanguage, :integer
    add_column :hmis_aggregated_enrollments, :PreferredLanguageDifferent, :string

    add_column :hmis_aggregated_exits, :DestinationSubsidyType, :integer
  end
end
