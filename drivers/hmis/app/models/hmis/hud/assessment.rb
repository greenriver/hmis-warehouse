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

  def self.assessment_types_enum_map
    Hmis::FieldMap.new(
      ::HUD.assessment_types.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end

  def self.assessment_levels_enum_map
    Hmis::FieldMap.new(
      ::HUD.assessment_levels.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end

  def self.prioritization_statuses_enum_map
    Hmis::FieldMap.new(
      ::HUD.prioritization_statuses.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end
end
