class HmisDataCleanup::DuplicateRecordsReport
  def duplicate_custom_assessments(data_source)
    # to reduce the search space, find the enrollment ids that might be duplicates
    candidate_enrollment_ids = Hmis::Hud::CustomAssessment.
      where(data_source: data_source).
      joins(:form_processor).group(:EnrollmentID, :definition_id, :AssessmentDate).
      having('COUNT(*) > 1').
      count.
      keys.map { |k| k[0] }

    find_true_duplicates(candidate_enrollment_ids, Hmis::Hud::CustomAssessment.where(data_source: data_source))
  end

  def duplicate_custom_services(data_source)
    # to reduce the search space, find the enrollment ids that might be duplicates
    candidate_enrollment_ids = Hmis::Hud::CustomService.
      where(data_source: data_source).
      group(:EnrollmentID, :custom_service_type_id, :DateProvided).
      having('COUNT(*) > 1').
      count.
      keys.map { |k| k[0] }

    find_true_duplicates(candidate_enrollment_ids, Hmis::Hud::CustomService.where(data_source: data_source))
  end

  protected

  def find_true_duplicates(enrollment_ids, scope)
    by_identity = {}
    enrollment_ids.in_groups_of(500).each do |enrollment_id_batch|
      batch = scope.where(EnrollmentID: enrollment_id_batch)
      batch.preload(:custom_data_elements).find_each do |record|
        identity = identify_for_deduplication(record)
        by_identity[identity] ||= []
        by_identity[identity].push(record.id)
      end
    end
    by_identity.values.filter(&:many?)
  end

  def identify_for_deduplication(record)
    identity_attributes = record.attributes.except('id', record.hud_key.to_s, 'UserID', 'DateCreated', 'DateUpdated', 'DateDeleted', 'lock_version').map do |item|
      item.join(':')
    end
    cde_attributes = record.custom_data_elements.to_a.map do |cde|
      [cde.data_element_definition_id.to_s, cde.value.to_s].join(':')
    end.sort
    [identity_attributes, cde_attributes].flat_map { |ary| ary.join(':') }
  end
end
