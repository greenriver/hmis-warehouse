###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Assessment < Hmis::Hud::Base
  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Shared
  self.table_name = :Assessment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  has_one :assessment_detail, class_name: 'Hmis::Form::AssessmentDetail'

  use_enum :assessment_types_enum_map, ::HUD.assessment_types
  use_enum :assessment_levels_enum_map, ::HUD.assessment_levels
  use_enum :prioritization_statuses_enum_map, ::HUD.prioritization_statuses

  SORT_OPTIONS = [:assessment_date].freeze

  def self.generate_assessment_id
    generate_uuid
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :assessment_date
      order(AssessmentDate: :desc)
    else
      raise NotImplementedError
    end
  end
end
