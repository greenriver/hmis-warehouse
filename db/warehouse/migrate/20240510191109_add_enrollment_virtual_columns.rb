class AddEnrollmentVirtualColumns < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    [
      'Enrollment',
      'Disabilities',
      'EmploymentEducation',
      'Exit',
      'HealthAndDV',
      'IncomeBenefits',
      'Services',
      'CurrentLivingSituation',
      'CustomAssessments',
      'CustomServices',
      'Assessment',
      'AssessmentQuestions',
      'AssessmentResults',
      'Event',
      'YouthEducationStatus',
    ].each do |table_name|
      # Postgres doesn't currently support virtual columns yet, so storing them.
      next if column_exists?(table_name.to_sym, :enrollment_slug)

      column_def = <<~SQL
        ("EnrollmentID" || ':' || "PersonalID" || ':' || "data_source_id"::text)
      SQL
      add_column(
        table_name.to_sym,
        :enrollment_slug,
        :string,
        as: column_def,
        stored: true,
      )

      # add_column_query = <<~SQL
      #   ALTER TABLE "#{table_name}"
      #   ADD COLUMN enrollment_slug
      #   VARCHAR(200) GENERATED ALWAYS AS ("EnrollmentID" || ':' || "PersonalID" || ':' || "data_source_id"::text)
      #   VIRTUAL
      # SQL
      # safety_assured do
      #   execute(add_column_query)
      # end
    end
  end
end
