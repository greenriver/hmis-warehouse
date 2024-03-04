###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Assessment < Hmis::Hud::Base
  self.table_name = :Assessment
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze

  SORT_OPTION_DESCRIPTIONS = {
    assessment_date: 'Assessment Date: Most Recent First',
    date_updated: 'Last Updated: Most Recent First',
  }.freeze

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :assessment_questions, **hmis_relation(:AssessmentID, 'AssessmentQuestion'), dependent: :destroy
  has_many :assessment_results, **hmis_relation(:AssessmentID, 'AssessmentResult'), dependent: :destroy

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :assessment_date
      order(assessment_date: :desc, date_created: :desc)
    when :date_updated
      order(date_updated: :desc)
    else
      raise NotImplementedError
    end
  end
end
