desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
  return unless data_source_id.present?

  system_user = Hmis::User.find(User.system_user.id)
  system_user.hmis_data_source_id = data_source_id
  hud_user = Hmis::Hud::User.from_user(system_user)

  # Loads all HUD service types, and organizes them by Category according to the record type.
  # Once we introduce actual custom services and the ability to customize how HUD services are categorized,
  # this will need to change.

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
