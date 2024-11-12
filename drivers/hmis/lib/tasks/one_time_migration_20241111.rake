desc 'One time data migration to populate created_by and updated_by on Custom Assessments'
# rails driver:hmis:migrate_assessments_20241111
task migrate_assessments_20241111: [:environment] do
  assessments = Hmis::Hud::CustomAssessment.joins(:versions).distinct
  total_records = assessments.count

  assessments.find_each.with_index(1) do |custom_assessment, index|
    versions = custom_assessment.versions.order(created_at: :desc)
    update_version = versions.first
    create_version = versions.find_by(event: "create")

    if !create_version || !update_version
      puts "Check versions of #{custom_assessment.id}. It has versions but they look incorrect. Skipping."
      next
    end

    # use `update_column` to bypass paper trail and timestamp updates
    custom_assessment.update_column(:created_by_user_id, create_version.clean_true_user_id || create_version.clean_user_id) if create_version
    custom_assessment.update_column(:updated_by_user_id, update_version.clean_true_user_id || update_version.clean_user_id) if update_version

    if index % 100 == 0 || index == total_records
      puts "Processed #{index} of #{total_records}"
    end
  end
end
