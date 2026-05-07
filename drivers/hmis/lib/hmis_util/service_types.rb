# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class ServiceTypes
    # Ensures all HUD service types exist in CustomServiceTypes table,
    # and organizes them by Category according to the record type.
    def self.seed_hud_service_types(data_source_id)
      raise "Not an HMIS data source: #{data_source_id}" unless GrdaWarehouse::DataSource.hmis.exists?(id: data_source_id)

      Rails.logger.info "Seeding HUD Service Types for DS##{data_source_id}"
      hud_user = Hmis::Hud::User.system_user(data_source_id: data_source_id)

      HudHelper.util.record_types.each do |record_type, category_name|
        # Find or create service category (eg "SSVF Service")
        category = Hmis::Hud::CustomServiceCategory.create_with(
          user_id: hud_user.user_id,
        ).find_or_create_by!(
          name: category_name,
          data_source_id: data_source_id,
        )

        # For each HUD TypeProvided under this RecordType, ensure a CustomServiceType record exists
        type_provided_map = Hmis::Hud::Validators::ServiceValidator::TYPE_PROVIDED_MAP[record_type]
        type_provided_map.each do |type_provided, service_name|
          Hmis::Hud::CustomServiceType.create_with(
            user_id: hud_user.user_id,
            name: service_name,
            custom_service_category: category,
          ).find_or_create_by!(
            hud_record_type: record_type,
            hud_type_provided: type_provided,
            data_source_id: data_source_id,
          )
        end
      end
    end
  end
end
