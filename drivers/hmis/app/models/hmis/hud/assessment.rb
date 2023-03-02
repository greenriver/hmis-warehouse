###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Assessment < Hmis::Hud::Base
  self.table_name = :Assessment
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Concerns::HmisArelHelper

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
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
