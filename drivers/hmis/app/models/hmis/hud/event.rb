###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Event < Hmis::Hud::Base
  include ::HmisStructure::Event
  include ::Hmis::Hud::Shared
  self.table_name = :Event
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')

  def self.events_enum_map
    Hmis::FieldMap.new(
      ::HUD.events.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end

  def self.referral_result_enum_map
    Hmis::FieldMap.new(
      ::HUD.referral_results.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end

  def self.prob_sol_div_rr_result_enum_map
    Hmis::FieldMap.yes_no_missing
  end

  def self.referral_case_manage_after_enum_map
    Hmis::FieldMap.yes_no_missing
  end
end
