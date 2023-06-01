###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class ServiceTypes
    # Ensures all HUD service types exist in CustomServiceTypes table,
    # and organizes them by Category according to the record type.
    def self.seed_hud_service_types(data_source_id)
      system_user = Hmis::User.find(User.system_user.id)
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

    HUD_SERVICE_INSTANCE_CONFIG = [
      {
        record_type: 200, # BedNight
        project_types: [
          1, # ES
          0, # ES NBN (2024)
        ],
      },
      {
        record_type: 141, # P1 Services Provided - PATH Funded
        project_types: [
          4, # Street Outreach
          6, # Services Only
        ],
        funders: [21], # HHS: PATH - Street Outreach & Supportive Services Only
      },
      {
        record_type: 161, # P2 Referrals Provided - PATH
        project_types: [
          4, # Street Outreach
          6, # Services Only
        ],
        funders: [21], # HHS: PATH - Street Outreach & Supportive Services Only
      },
      {
        record_type: 300, # C2 Moving On Assistance Provided
        project_types: [
          3, # PSH
        ],
        funders: [2], # HUD: CoC - Permanent Supportive Housing
      },
    ].freeze

    # Ensures that Form Instances exist for each HUD Service Type according to the configuration.
    def self.seed_hud_service_form_instances
      HUD_SERVICE_INSTANCE_CONFIG.each do |config|
        (record_type, type_provided, project_types) = config.values_at(:record_type, :type_provided, :project_types)

        csts = Hmis::Hud::CustomServiceType.where(hud_record_type: record_type)

        custom_service_type = csts.where(hud_type_provided: type_provided).first if type_provided.present?
        custom_service_category = csts.first.custom_service_category unless type_provided.present?
        next unless custom_service_type.present? || custom_service_category.present?

        # puts "Ensuring '#{custom_service_category&.name}' instances for #{project_types.size} project types"
        (project_types || [nil]).each do |project_type|
          Hmis::Form::Instance.where(
            entity_type: 'ProjectType',
            entity_id: project_type,
            definition_identifier: 'service', # The default definition used for all HUD Services
            custom_service_type_id: custom_service_type&.id,
            custom_service_category_id: custom_service_category&.id,
            # funder: funder,
          ).first_or_create
        end
      end
    end
  end
end
