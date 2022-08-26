###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Service < Hmis::Hud::Base
  include ::HmisStructure::Service
  include ::Hmis::Hud::Shared
  self.table_name = :Services
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')

  use_enum :record_type_enum_map, (::HUD.record_types.reject { |_k, v| v == 'Contact' })
  use_enum :p_a_t_h_referral_outcome_enum_map, ::HUD.p_a_t_h_referral_outcome_map

  # Enums for TypeProvided
  use_enum :p_a_t_h_service_enum_map, ::HUD.p_a_t_h_services_map
  use_enum :r_h_y_service_enum_map, ::HUD.r_h_y_services_map
  use_enum :h_o_p_w_a_service_enum_map, ::HUD.h_o_p_w_a_services_map
  use_enum :s_s_v_f_service_enum_map, ::HUD.s_s_v_f_services_map
  use_enum :h_o_p_w_a_financial_assistance_enum_map, ::HUD.h_o_p_w_a_financial_assistance_map
  use_enum :s_s_v_f_financial_assistance_enum_map, ::HUD.s_s_v_f_financial_assistance_map
  use_enum :p_a_t_h_referral_enum_map, ::HUD.p_a_t_h_referral_map
  use_enum :bed_night_enum_map, ::HUD.bed_night_map
  use_enum :voucher_tracking_enum_map, ::HUD.voucher_tracking_map
  use_enum :moving_on_assistance_enum_map, ::HUD.moving_on_assistance_map
end
