desc 'One time data migration to populate created_by and updated_by on Custom Assessments'
# rails driver:hmis:migrate_assessments_20241111
task migrate_assessments_20241111: [:environment] do
  assessments = Hmis::Hud::CustomAssessment.preload(:versions)
  total_records = assessments.count

  assessments.find_each.with_index(1) do |custom_assessment, index|
    # use array methods since this is preloaded
    versions = custom_assessment.versions.to_a.filter do |version|
      version.clean_true_user_id || version.clean_user_id
    end
    next if versions.blank?

    update_version = versions.max_by(&:created_at)
    create_version = versions.detect { |v| v.event == 'create' }

    attrs = {}
    attrs[:created_by_user_id] = create_version.clean_true_user_id || create_version.clean_user_id if create_version
    attrs[:updated_by_user_id] = update_version.clean_true_user_id || update_version.clean_user_id # update_version will always be present
    # use `update_columns` to bypass paper trail and timestamp updates
    custom_assessment.update_columns(**attrs)

    if index % 100 == 0 || index == total_records
      puts "Processed #{index} of #{total_records}"
    end
  end
end
