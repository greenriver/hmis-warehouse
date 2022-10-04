class Hmis::Hud::Validators::ServiceValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  TYPE_PROVIDED_MAP = {
    141 => ::HUD.p_a_t_h_services_map,
    142 => ::HUD.r_h_y_services_map,
    143 => ::HUD.h_o_p_w_a_services_map,
    144 => ::HUD.s_s_v_f_services_map,
    151 => ::HUD.h_o_p_w_a_financial_assistance_map,
    152 => ::HUD.s_s_v_f_financial_assistance_map,
    161 => ::HUD.p_a_t_h_referral_map,
    200 => ::HUD.bed_night_map,
    210 => ::HUD.voucher_tracking_map,
    300 => ::HUD.moving_on_assistance_map,
  }.freeze

  SUB_TYPE_PROVIDED_MAP = {
    3 => ::HUD.s_s_v_f_sub_type3_map,
    4 => ::HUD.s_s_v_f_sub_type4_map,
    5 => ::HUD.s_s_v_f_sub_type5_map,
  }.freeze

  def configuration
    Hmis::Hud::Service.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      validate_record_type(record)
      validate_type_provided(record)
      validate_sub_type_provided(record)
    end
  end

  def validate_record_type(record)
    return if ::HUD.record_types.reject { |_k, v| v == 'Contact' }.any? { |k, _v| record.record_type == k }

    record.errors.add :record_type, :invalid, message: 'Invalid RecordType', full_message: "Value for RecordType '#{record.record_type}' is not a valid RecordType"
  end

  def validate_type_provided(record)
    return if TYPE_PROVIDED_MAP.any? { |rt, tp_map| record.record_type == rt && tp_map.keys.include?(record.type_provided) }

    record.errors.add :type_provided, :invalid, message: 'Invalid TypeProvided for RecordType', full_message: "Value for TypeProvided '#{record.type_provided}' does not match RecordType '#{record.record_type}'"
  end

  def validate_sub_type_provided(record)
    return unless record.record_type == 144 && record.sub_type_provided.present?
    return record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for RecordType', full_message: "SubTypeProvided must be null unless RecordType = 144. RecordType is #{record.record_type}" if record.sub_type_provided.present? && record.record_type != 144
    return record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for TypeProvided', full_message: "SubTypeProvided must be null unless TypeProvided is 3, 4 or 5. TypeProvided is #{record.type_provided}" unless SUB_TYPE_PROVIDED_MAP.keys.include?(record.type_provided)
    return if SUB_TYPE_PROVIDED_MAP.any? { |rt, tp_map| record.type_provided == rt && tp_map.keys.include?(record.sub_type_provided) }

    record.errors.add :sub_type_provided, :invalid, message: 'Invalid SubTypeProvided for TypeProvided', full_message: "Value for SubTypeProvided '#{record.sub_type_provided}' does not match TypeProvided '#{record.type_provided}'"
  end
end
