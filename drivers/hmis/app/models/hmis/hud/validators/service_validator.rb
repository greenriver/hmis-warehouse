###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ServiceValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    :TypeProvided,
    :RecordType,
  ].freeze

  TYPE_PROVIDED_MAP = {
    141 => ::HudLists.path_services_map,
    142 => ::HudLists.rhy_services_map,
    143 => ::HudLists.hopwa_services_map,
    144 => ::HudLists.ssvf_services_map,
    151 => ::HudLists.hopwa_financial_assistance_map,
    152 => ::HudLists.ssvf_financial_assistance_map,
    161 => ::HudLists.path_referral_map,
    162 => ::HudLists.rhy_referral_map,
    200 => ::HudLists.bed_night_map,
    210 => ::HudLists.voucher_tracking_map,
    300 => ::HudLists.moving_on_assistance_map,
  }.freeze

  SUB_TYPE_PROVIDED_MAP = {
    3 => ::HudLists.ssvf_sub_type3_map,
    4 => ::HudLists.ssvf_sub_type4_map,
    5 => ::HudLists.ssvf_sub_type5_map,
  }.freeze

  def configuration
    Hmis::Hud::Service.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      self.class.validate_service_type(record)
      self.class.validate_sub_type_provided(record)
    end
  end

  def self.validate_service_type(record, record_type_field: :record_type, type_provided_field: :type_provided)
    record_type = record.send(record_type_field)
    type_provided = record.send(type_provided_field)

    record.errors.add type_provided_field, :required unless record_type.present? && type_provided.present?
    return unless record_type.present? && type_provided.present?

    unless ::HudUtility.record_types.reject { |_k, v| v == 'Contact' }.any? { |k, _v| record_type == k }
      record.errors.add type_provided_field, :invalid, full_message: "Service type category '#{record_type}' is not a valid category"
      return
    end

    return if TYPE_PROVIDED_MAP.any? { |rt, tp_map| record_type == rt && tp_map.keys.include?(type_provided) }

    record.errors.add type_provided_field, :invalid, full_message: "Value for service type '#{type_provided}' is not a valid service type for the category '#{record_type}'"
  end

  def self.validate_sub_type_provided(record)
    if record.record_type == 144
      if SUB_TYPE_PROVIDED_MAP.keys.include?(record.type_provided)
        record.errors.add :sub_type_provided, :invalid, full_message: "Value for SubTypeProvided '#{record.sub_type_provided}' does not match TypeProvided '#{record.type_provided}'" unless SUB_TYPE_PROVIDED_MAP.any? { |tp, stp_map| record.type_provided == tp && stp_map.keys.include?(record.sub_type_provided) }
      elsif record.sub_type_provided.present?
        record.errors.add :sub_type_provided, :invalid, full_message: "SubTypeProvided must be null unless TypeProvided is 3, 4 or 5. TypeProvided is #{record.type_provided}"
      end
    elsif record.sub_type_provided.present?
      record.errors.add :sub_type_provided, :invalid, full_message: "SubTypeProvided must be null unless RecordType = 144. RecordType is #{record.record_type}"
    end
  end
end
