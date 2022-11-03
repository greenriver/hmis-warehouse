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
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ServiceValidator

  use_enum :record_type_enum_map, (::HUD.record_types.reject { |_k, v| v == 'Contact' })
  use_enum :p_a_t_h_referral_outcome_enum_map, ::HUD.p_a_t_h_referral_outcome_map

  # Enums for TypeProvided
  use_enum :p_a_t_h_service_enum_map, ::HUD.p_a_t_h_services_map # If record type 141
  use_enum :r_h_y_service_enum_map, ::HUD.r_h_y_services_map # If record type 142
  use_enum :h_o_p_w_a_service_enum_map, ::HUD.h_o_p_w_a_services_map # If record type 143
  use_enum :s_s_v_f_service_enum_map, ::HUD.s_s_v_f_services_map # If record type 144
  use_enum :h_o_p_w_a_financial_assistance_enum_map, ::HUD.h_o_p_w_a_financial_assistance_map # If record type 151
  use_enum :s_s_v_f_financial_assistance_enum_map, ::HUD.s_s_v_f_financial_assistance_map # If record type 152
  use_enum :p_a_t_h_referral_enum_map, ::HUD.p_a_t_h_referral_map # If record type 161
  use_enum :bed_night_enum_map, ::HUD.bed_night_map # If record type 200
  use_enum :voucher_tracking_enum_map, ::HUD.voucher_tracking_map # If record type 210
  use_enum :moving_on_assistance_enum_map, ::HUD.moving_on_assistance_map # If record type 300

  # Enums for SubTypeProvided (Only present if record type 144 and type provided 3, 4 or 5)
  use_enum :s_s_v_f_sub_type3_enum_map, ::HUD.s_s_v_f_sub_type3_map # If type provded 3
  use_enum :s_s_v_f_sub_type4_enum_map, ::HUD.s_s_v_f_sub_type4_map # If type provded 4
  use_enum :s_s_v_f_sub_type5_enum_map, ::HUD.s_s_v_f_sub_type5_map # If type provded 5

  SORT_OPTIONS = [:date_provided].freeze

  scope :viewable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
  end

  scope :editable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.editable_by(user))
  end

  def self.generate_services_id
    generate_uuid
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_provided
      order(DateProvided: :desc)
    else
      raise NotImplementedError
    end
  end
end
