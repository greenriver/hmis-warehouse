class Hmis::Hud::Validators::ServiceValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :TypeProvided,
    :RecordType,
  ].freeze

  TYPE_PROVIDED_MAP = {
    141 => ::HudUtility.p_a_t_h_services_map,
    142 => ::HudUtility.r_h_y_services_map,
    143 => ::HudUtility.h_o_p_w_a_services_map,
    144 => ::HudUtility.s_s_v_f_services_map,
    151 => ::HudUtility.h_o_p_w_a_financial_assistance_map,
    152 => ::HudUtility.s_s_v_f_financial_assistance_map,
    161 => ::HudUtility.p_a_t_h_referral_map,
    200 => ::HudUtility.bed_night_map,
    210 => ::HudUtility.voucher_tracking_map,
    300 => ::HudUtility.moving_on_assistance_map,
  }.freeze

  SUB_TYPE_PROVIDED_MAP = {
    3 => ::HudUtility.s_s_v_f_sub_type3_map,
    4 => ::HudUtility.s_s_v_f_sub_type4_map,
    5 => ::HudUtility.s_s_v_f_sub_type5_map,
  }.freeze

  def configuration
    Hmis::Hud::Service.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      validate_service_type(record)
      validate_sub_type_provided(record)
    end
  end

  def validate_service_type(record)
    record.errors.add :type_provided, :required, message: 'must exist' unless record.record_type.present? && record.type_provided.present?
    return unless record.record_type.present? && record.type_provided.present?
    return if ::HudUtility.record_types.reject { |_k, v| v == 'Contact' }.any? { |k, _v| record.record_type == k }

    record.errors.add :type_provided, :invalid, message: 'is invalid', full_message: "Service type category '#{record.record_type}' is not a valid category"
    return if TYPE_PROVIDED_MAP.any? { |rt, tp_map| record.record_type == rt && tp_map.keys.include?(record.type_provided) }

    record.errors.add :type_provided, :invalid, message: 'Invalid service type', full_message: "Value for service type '#{record.type_provided}' is not a valid service type for the category '#{record.record_type}'"
  end

  def validate_sub_type_provided(record)
    if record.record_type == 144
      if SUB_TYPE_PROVIDED_MAP.keys.include?(record.type_provided)
        record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for TypeProvided', full_message: "Value for SubTypeProvided '#{record.sub_type_provided}' does not match TypeProvided '#{record.type_provided}'" unless SUB_TYPE_PROVIDED_MAP.any? { |tp, stp_map| record.type_provided == tp && stp_map.keys.include?(record.sub_type_provided) }
      else
        record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for TypeProvided', full_message: "SubTypeProvided must be null unless TypeProvided is 3, 4 or 5. TypeProvided is #{record.type_provided}"
      end
    elsif record.sub_type_provided.present?
      record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for RecordType', full_message: "SubTypeProvided must be null unless RecordType = 144. RecordType is #{record.record_type}"
    end
  end
end
