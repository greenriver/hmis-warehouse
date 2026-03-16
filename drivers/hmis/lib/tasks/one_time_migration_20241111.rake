desc 'One time data migration to populate created_by and updated_by on Custom Assessments'
# rails driver:hmis:migrate_assessment_user_references_20241111
task migrate_assessment_user_references_20241111: [:environment] do
  data_source = GrdaWarehouse::DataSource.hmis.sole
  assessments = Hmis::Hud::CustomAssessment.where(data_source: data_source).joins(:user).preload(:versions)
  total_records = assessments.count
  updated_count = 0

  hud_user_local_cache = {} # Cache to store users in memory, reducing db hits

  def find_or_create_hud_user(user_id, hud_user_local_cache, data_source)
    hud_user_local_cache[user_id] ||= begin
      user = Hmis::User.find(user_id)
      user.hmis_data_source_id = data_source.id
      hud_user = Hmis::Hud::User.from_user(user)
      hud_user
    end
  end

  assessments.find_each.with_index(1) do |assessment, index|
    # use array methods since this is preloaded
    versions = assessment.versions.to_a.filter do |version|
      version.clean_true_user_id || version.clean_user_id
    end

    unless versions.blank?
      update_version = versions.max_by(&:created_at)
      create_version = versions.detect { |v| v.event == 'create' }

      attrs = {}

      if create_version
        user_id = create_version.clean_true_user_id || create_version.clean_user_id
        hud_user = find_or_create_hud_user(user_id, hud_user_local_cache, data_source)
        attrs[:created_by_hud_user_id] = hud_user.id
      end

      if update_version
        user_id = update_version.clean_true_user_id || update_version.clean_user_id
        hud_user = find_or_create_hud_user(user_id, hud_user_local_cache, data_source)
        attrs[:updated_by_hud_user_id] = hud_user.id
      end

      # use `update_columns` to bypass paper trail and timestamp updates
      assessment.update_columns(**attrs)
      updated_count += 1
    end

    if index % 1000 == 0 || index == total_records
      puts "Processed #{index} of #{total_records}. Updated #{updated_count}."
    end
  end
end
