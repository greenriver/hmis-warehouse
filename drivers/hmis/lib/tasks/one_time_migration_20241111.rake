desc 'One time data migration to populate created_by and updated_by on Custom Assessments'
# rails driver:hmis:migrate_assessments_20241111
task migrate_assessments_20241111: [:environment] do
  assessments = Hmis::Hud::CustomAssessment.joins(:user).preload(:versions)
  total_records = assessments.count
  updated_count = 0

  user_ids = Set.new
  data_source_ids = Set.new

  assessments.find_each.with_index(1) do |assessment, index|
    # use array methods since this is preloaded
    versions = assessment.versions.to_a.filter do |version|
      version.clean_true_user_id || version.clean_user_id
    end

    unless versions.blank?
      update_version = versions.max_by(&:created_at)
      create_version = versions.detect { |v| v.event == 'create' }

      attrs = {}

      attrs[:updated_by_user_id] = (update_version.clean_true_user_id || update_version.clean_user_id) # update_version will always be present

      if create_version
        attrs[:created_by_user_id] = (create_version.clean_true_user_id || create_version.clean_user_id)
        user_ids << (create_version.clean_true_user_id || create_version.clean_user_id)
        data_source_ids << assessment.data_source_id
      end

      # use `update_columns` to bypass paper trail and timestamp updates
      assessment.update_columns(**attrs)

      updated_count += 1
    end

    if index % 1000 == 0 || index == total_records
      puts "Processed #{index} of #{total_records}. Updated #{updated_count}."
    end
  end

  # explicitly do not support multiple data sources
  raise 'unexpectedly found multiple HMIS data sources' if data_source_ids.size > 1

  # find (and if needed, save) a HUD user for each app user we encountered
  app_user_ids_to_hud_users = {}
  user_ids.each do |user_id|
    user = Hmis::User.find(user_id)
    user.hmis_data_source_id = data_source_ids.first
    hud_user = Hmis::Hud::User.from_user(user)
    hud_user.save!
    app_user_ids_to_hud_users[user_id] = hud_user
  end

  users_to_import = app_user_ids_to_hud_users.values.filter { |user| !user.persisted? }
  puts "Encountered #{user_ids.size} app users, of which #{users_to_import.size} don't yet have a corresponding HUD user."
  Hmis::Hud::User.import(users_to_import)

  assessments = Hmis::Hud::CustomAssessment.where(created_by_hud_user: nil).preload(:versions)
  total_records = assessments.count
  puts "Now going back through to update #{total_records} assessments with their `created_by_hud_user`"

  assessments.find_each.with_index(1) do |assessment, index|
    hud_user_id = app_user_ids_to_hud_users[assessment.created_by_hud_user]&.id
    assessment.update_column!(:created_by_hud_user_id, hud_user_id)

    if index % 1000 == 0 || index == total_records
      puts "Processed #{index} of #{total_records}."
    end
  end
end
