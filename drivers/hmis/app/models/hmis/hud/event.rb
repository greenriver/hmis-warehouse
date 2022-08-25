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

  use_enum :events_enum_map, ::HUD.events
  use_enum :referral_result_enum_map, ::HUD.referral_results
  use_common_enum :prob_sol_div_rr_result_enum_map, :yes_no_missing
  use_common_enum :referral_case_manage_after_enum_map, :yes_no_missing
end
