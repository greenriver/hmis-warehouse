# This migration replaces composite primary keys with generated columns.
# The composite_primary_keys gem is being deprecated and will no longer be maintained.
# To maintain the same functionality, we are creating stored generated columns
# that concatenate the data_source_id with the original ID columns.
# This allows us to maintain unique identifiers across data sources while
# moving away from the deprecated gem.
class ReplaceCompositeKeys < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      composite_cols.each do |table_name, id_column|
        key = composite_key(table_name, id_column)
        execute <<-SQL
          ALTER TABLE #{connection.quote_table_name(table_name)}
          ADD COLUMN #{connection.quote_column_name(key)} VARCHAR GENERATED ALWAYS AS (data_source_id || ':' || #{connection.quote_column_name(id_column)}) STORED;
        SQL

        execute <<-SQL
          CREATE INDEX #{connection.quote_column_name(index_name(table_name, key))}
          ON #{connection.quote_table_name(table_name)} (#{connection.quote_column_name(key)})
        SQL
      end

      composite_cols.map(&:first).uniq.each do |table_name|
        execute <<-SQL
          ANALYZE #{connection.quote_table_name(table_name)}
        SQL
      end
    end
  end

  def down
    safety_assured do
      composite_cols.each do |table_name, id_column|
        key = composite_key(table_name, id_column)
        execute <<-SQL
          DROP INDEX IF EXISTS #{connection.quote_column_name(index_name(table_name, key))};
        SQL
        execute <<-SQL
          ALTER TABLE #{connection.quote_table_name(table_name)} DROP COLUMN #{connection.quote_column_name(key)}
        SQL
      end
    end
  end

  protected

  def index_name(table_name, key)
    "idx_#{table_name.downcase}_#{key}"
  end

  def composite_key(_table_name, id_column)
    "ds_#{id_column.gsub(/ID\z/, '').downcase}_id"
  end

  # def connection
  #  GrdaWarehouseBase.connection
  # end

  def composite_cols
    [
      ['Funder', 'FunderID'],
      ['Funder', 'ProjectID'],
      ['Inventory', 'ProjectID'],
      ['Affiliation', 'ProjectID'],
      ['Affiliation', 'AffiliationID'],
      ['User', 'UserID'],
      ['User', 'ExportID'],
      ['Project', 'ProjectID'],
      ['Project', 'OrganizationID'],
      ['Project', 'UserID'],
      ['Project', 'ExportID'],
      ['CEParticipation', 'ExportID'],
      ['CEParticipation', 'ProjectID'],
      ['CEParticipation', 'UserID'],
      ['Client', 'ExportID'],
      ['Client', 'PersonalID'],
      ['Client', 'UserID'],
      ['HMISParticipation', 'ProjectID'],
      ['CurrentLivingSituation', 'EnrollmentID'],
      ['Organization', 'OrganizationID'],
      ['Organization', 'UserID'],
      ['Organization', 'ExportID'],
      ['Enrollment', 'ProjectID'],
      ['Enrollment', 'PersonalID'],
      ['Enrollment', 'UserID'],
      ['Enrollment', 'ExportID'],
      ['Enrollment', 'EnrollmentID'],
      ['EnrollmentCoC', 'EnrollmentID'],
      ['EnrollmentCoC', 'ProjectID'],
      ['EnrollmentCoC', 'ExportID'],
      ['EnrollmentCoC', 'UserID'],
      ['EnrollmentCoC', 'PersonalID'],
      ['ProjectCoC', 'ProjectCoCID'],
      ['ProjectCoC', 'ProjectID'],
      ['ProjectCoC', 'UserID'],
      ['ProjectCoC', 'ExportID'],
      ['Exit', 'EnrollmentID'],
      ['Exit', 'ExitID'],
      ['Exit', 'UserID'],
      ['Exit', 'PersonalID'],
      ['Exit', 'ExportID'],
      ['Export', 'ExportID'],
      ['IncomeBenefits', 'EnrollmentID'],
      ['IncomeBenefits', 'IncomeBenefitsID'],
      ['IncomeBenefits', 'UserID'],
      ['IncomeBenefits', 'PersonalID'],
      ['IncomeBenefits', 'ExportID'],
      ['HealthAndDV', 'EnrollmentID'],
      ['HealthAndDV', 'HealthAndDVID'],
      ['HealthAndDV', 'UserID'],
      ['HealthAndDV', 'PersonalID'],
      ['HealthAndDV', 'ExportID'],
      ['EmploymentEducation', 'EnrollmentID'],
      ['EmploymentEducation', 'EmploymentEducationID'],
      ['EmploymentEducation', 'UserID'],
      ['EmploymentEducation', 'PersonalID'],
      ['EmploymentEducation', 'ExportID'],
      ['Disabilities', 'DisabilitiesID'],
      ['Disabilities', 'EnrollmentID'],
      ['Disabilities', 'PersonalID'],
      ['Disabilities', 'UserID'],
      ['Disabilities', 'ExportID'],
      ['Services', 'EnrollmentID'],
      ['Services', 'ServicesID'],
      ['Services', 'PersonalID'],
      ['Services', 'UserID'],
      ['Services', 'ExportID'],
      ['Assessment', 'AssessmentID'],
      ['Assessment', 'EnrollmentID'],
      ['Assessment', 'PersonalID'],
      ['Assessment', 'UserID'],
      ['Assessment', 'ExportID'],
      ['AssessmentQuestions', 'AssessmentQuestionID'],
      ['AssessmentQuestions', 'AssessmentID'],
      ['AssessmentQuestions', 'EnrollmentID'],
      ['AssessmentQuestions', 'PersonalID'],
      ['AssessmentQuestions', 'UserID'],
      ['AssessmentQuestions', 'ExportID'],
      ['AssessmentResults', 'AssessmentResultID'],
      ['AssessmentResults', 'AssessmentID'],
      ['AssessmentResults', 'EnrollmentID'],
      ['AssessmentResults', 'PersonalID'],
      ['AssessmentResults', 'UserID'],
      ['AssessmentResults', 'ExportID'],
      ['Event', 'EventID'],
      ['Event', 'EnrollmentID'],
      ['Event', 'PersonalID'],
      ['Event', 'UserID'],
      ['Event', 'ExportID'],
      ['YouthEducationStatus', 'YouthEducationStatusID'],
      ['YouthEducationStatus', 'EnrollmentID'],
      ['YouthEducationStatus', 'PersonalID'],
      ['YouthEducationStatus', 'UserID'],
      ['YouthEducationStatus', 'ExportID'],
    ]
  end
end
