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

      HudUtility.record_types.except(12, 13).each do |record_type, category_name|
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

    BED_NIGHT_CONFIG = {
      record_type: 200, # BedNight
      project_types: [
        0, # Emergency Shelter - Entry Exit
        1, # Emergency Shelter - NbN
      ],
    }.freeze

    P1_PATH_SERVICE_CONFIG = {
      record_type: 141, # P1 Services Provided - PATH Funded
      funders: [21], # HHS: PATH - Street Outreach & Supportive Services Only
    }.freeze

    P2_PATH_REFERRAL_CONFIG = {
      record_type: 161, # P2 Referrals Provided - PATH
      funders: [21], # HHS: PATH - Street Outreach & Supportive Services Only
    }.freeze

    R14_RHY_SERVICE_CONFIG = {
      record_type: 142, # R14 RHY Service Connections
      # All HHS RHY funders except the Street Outreach one (25), plus YHDP (43)
      funders: HudUtility.funding_sources.select { |_, v| v.start_with?('HHS: RHY') }.keys - [25] + [43],
    }.freeze

    W1_HOPWA_SERVICE_CONFIG = {
      record_type: 143, # W1 Services Provided – HOPWA
      # Note: commenting out projects to leave the baseline more flexible. HOPWA services can optionally
      # be recorded for any service type.
      # project_types: [
      #   0, # Emergency Shelter - Entry Exit
      #   1, # Emergency Shelter - NbN
      #   2, # Transitional Housing
      #   3, # PH - Permanent Supportive Housing
      #   6, # Services Only
      #   12, # Homelessness Prevention
      # ],
      funders: HudUtility.funding_sources.select { |_, v| v.start_with?('HUD: HOPWA') }.keys,
    }.freeze

    W2_HOPWA_FINANCIAL_CONFIG = {
      record_type: 151, # W2 Financial Assistance - HOPWA
      # Note: commenting out projects to leave the baseline more flexible. HOPWA services can optionally
      # be recorded for any service type.
      # project_types: [
      #   6, # Services Only
      #   12, # Homelessness Prevention
      # ],
      funders: HudUtility.funding_sources.select { |_, v| v.start_with?('HUD: HOPWA') }.keys,
    }.freeze

    V2_SSVF_SERVICE_CONFIG = {
      record_type: 144, # V2 Services Provided – SSVF
      # 33 - VA: SSVF - Collection required only for RRH(13) & HP(12)
      # Optional for all other VA
      funders: HudUtility.funding_sources.select { |_, v| v.start_with?('VA:') }.keys,
    }.freeze

    V3_SSVF_FINANCIAL_CONFIG = {
      record_type: 152, # V3 Financial Assistance – SSVF
      funders: HudUtility.funding_sources.select { |_, v| v.start_with?('VA:') }.keys,
    }.freeze

    V8_HUD_VASH_VOUCHER_CONFIG = {
      record_type: 210, # V8 HUD-VASH Voucher Tracking
      project_types: [3], # PSH
      funders: [20], # HUD: HUD/VASH
    }.freeze

    C2_MOVING_ON_CONFIG = {
      record_type: 300, # C2 Moving On Assistance Provided
      funders: [2], # HUD: CoC - Permanent Supportive Housing
    }.freeze

    HUD_SERVICE_INSTANCE_CONFIG = [
      BED_NIGHT_CONFIG,
      P1_PATH_SERVICE_CONFIG,
      P2_PATH_REFERRAL_CONFIG,
      R14_RHY_SERVICE_CONFIG,
      W1_HOPWA_SERVICE_CONFIG,
      W2_HOPWA_FINANCIAL_CONFIG,
      V2_SSVF_SERVICE_CONFIG,
      V3_SSVF_FINANCIAL_CONFIG,
      V8_HUD_VASH_VOUCHER_CONFIG,
      C2_MOVING_ON_CONFIG,
    ].freeze

    # Set up initial Form Instances exist for each HUD Service Type according to the configuration.
    # These are NOT system-level instances; they can be deleted or changed as needed.
    def self.seed_hud_service_form_instances
      HUD_SERVICE_INSTANCE_CONFIG.each do |config|
        (record_type, project_types, funders) = config.values_at(:record_type, :project_types, :funders)

        custom_service_category = Hmis::Hud::CustomServiceType.where(hud_record_type: record_type).first&.custom_service_category
        raise "Category not found for record type #{record_type}" unless custom_service_category.present?

        # Create a Form Instance for each combination of project type + funder
        (project_types || [nil]).each do |project_type|
          (funders || [nil]).each do |funder|
            puts "Creating instance for '#{custom_service_category&.name}' ProjectType:#{project_type} Funder:#{funder}"
            Hmis::Form::Instance.where(
              definition_identifier: 'service', # The default definition used for all HUD Services
              custom_service_category_id: custom_service_category&.id,
              project_type: project_type,
              funder: funder,
              system: false, # Thesea aren't system records, they can be deleted.
              active: true,
            ).first_or_create
          end
        end
      end
    end
  end
end
