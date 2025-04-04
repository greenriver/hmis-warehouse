class ReplaceCompositeKeys < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      composite_cols.each do |table_name, id_column|
        key = composite_key(table_name, id_column)
        execute <<-SQL
          ALTER TABLE #{connection.quote_table_name(table_name)}
          ADD COLUMN #{connection.quote_column_name(key)} VARCHAR GENERATED ALWAYS AS (data_source_id || ':' || #{connection.quote_column_name(id_column)}) STORED;
        SQL
      end
    end
  end

  def down
    safety_assured do
      composite_cols.each do |table_name, id_column|
        key = composite_key(table_name, id_column)
        execute <<-SQL
          ALTER TABLE #{connection.quote_table_name(table_name)} DROP COLUMN #{connection.quote_column_name(key)}
        SQL
      end
    end
  end

  protected

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
      ['Client', 'ExportID'],
      ['Client', 'PersonalID'],
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
      ['ProjectCoC', 'ProjectCoCID'],
      ['ProjectCoC', 'ProjectID'],
      ['ProjectCoC', 'UserID'],
      ['ProjectCoC', 'ExportID'],
      ['Exit', 'EnrollmentID'],
      ['Exit', 'ExitID'],
      ['Exit', 'UserID'],
      ['Exit', 'PersonalID'],
      ['Exit', 'ExportID'],
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
