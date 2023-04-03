###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class ServiceTypes
    # Ensures all HUD service types exist in CustomServiceTypes table,
    # and organizes them by Category according to the record type.
    #
    # Once we introduce the ability to customize how HUD services are
    # categorized, this will need to change.
    def self.seed_hud_service_types(data_source_id)
      system_user = Hmis::User.system_user
      system_user.hmis_data_source_id = data_source_id
      hud_user = Hmis::Hud::User.from_user(system_user)

      HudLists.record_type_map.except(12, 13).each do |record_type, category_name|
        category = Hmis::Hud::CustomServiceCategory.where(
          name: category_name,
          data_source_id: data_source_id,
        ).first_or_create(user_id: hud_user.user_id)

        type_provided_map = Hmis::Hud::Validators::ServiceValidator::TYPE_PROVIDED_MAP[record_type]
        type_provided_map.each do |type_provided, service_name|
          Hmis::Hud::CustomServiceType.where(
            name: service_name,
            hud_record_type: record_type,
            hud_type_provided: type_provided,
            custom_service_category: category,
            data_source_id: data_source_id,
          ).first_or_create(user_id: hud_user.user_id)
        end
      end
    end
  end
end
