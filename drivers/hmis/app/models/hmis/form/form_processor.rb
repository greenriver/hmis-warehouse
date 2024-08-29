###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Stores the actual data that was collected during an assessment. 1:1 with CustomAssessments.
#   If the assessment is WIP: The data is stored exclusively as JSON blobs in the "values”/”hud_values" cols.
#   If the assessment is non-WIP: The HUD data is stored in records (IncomeBenefit, HealthAndDv, etc) that are referenced by this form_processor directly. (health_and_dv_id etc)
class Hmis::Form::FormProcessor < ::GrdaWarehouseBase
  self.table_name = :hmis_form_processors
  has_paper_trail

  # The 'owner' is the primary record that is being processed. Could be a CustomAssessment, Client, Project, etc.
  # TODO: change to optional: false
  belongs_to :owner, polymorphic: true, optional: true
  # TODO: remove this relation and drop the column
  belongs_to :custom_assessment, class_name: 'Hmis::Hud::CustomAssessment', optional: true

  # Definition that was most recently used to process this form
  belongs_to :definition, class_name: 'Hmis::Form::Definition', optional: true

  # Related records that were created/updated from this form
  # Note: these do not have dependent:destroy because we need to be able to clean up forms without
  # deleting records during migration. Deletion of related records happens with `destroy_dependent_records!`
  belongs_to :health_and_dv, class_name: 'Hmis::Hud::HealthAndDv', optional: true, autosave: true
  belongs_to :income_benefit, class_name: 'Hmis::Hud::IncomeBenefit', optional: true, autosave: true
  belongs_to :physical_disability, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :developmental_disability, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :chronic_health_condition, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :hiv_aids, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :mental_health_disorder, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :substance_use_disorder, class_name: 'Hmis::Hud::Disability', optional: true, autosave: true
  belongs_to :exit, class_name: 'Hmis::Hud::Exit', optional: true, autosave: true
  belongs_to :youth_education_status, class_name: 'Hmis::Hud::YouthEducationStatus', optional: true, autosave: true
  belongs_to :employment_education, class_name: 'Hmis::Hud::EmploymentEducation', optional: true, autosave: true
  belongs_to :current_living_situation, class_name: 'Hmis::Hud::CurrentLivingSituation', optional: true, autosave: true
  # Note: this is NOT the assessment that created this processor, that's CustomAssessment. Rather this is a
  # Coordinated Entry (CE) Assessment that was created by the processor. The HUD model for CE Assessment is 'Assessment'
  belongs_to :ce_assessment, class_name: 'Hmis::Hud::Assessment', optional: true, autosave: true
  belongs_to :ce_event, class_name: 'Hmis::Hud::Event', optional: true, autosave: true

  validate :hmis_records_are_valid, on: :form_submission

  attr_accessor :hud_user, :current_user

  def custom_assessment?
    owner_type == Hmis::Hud::CustomAssessment.sti_name
  end

  def unknown_field_error(definition)
    RuntimeError.new("Not a submittable field for Form Definition '#{definition.title}' (ID: #{definition.id})")
  end

  def run!(user:)
    # Set the HUD User and current user, so processors can store them on related records
    self.current_user = user
    self.hud_user = Hmis::Hud::User.from_user(user)

    return unless hud_values.present?

    raise 'No definition' unless definition.present?

    # Iterate through each 'container' (eg record type)
    hud_values_by_container.each do |container, field_name_to_value_h|
      # Iterate through each submitted value for this container
      field_name_to_value_h.each do |field, value|
        processor = container_processor(container)
        raise unknown_field_error(definition) unless processor

        if mapped_custom_form_fields[container].include?(field)
          # If this key can be identified as a CustomDataElement, set it and continue
          processor.process_custom_field(field, value)
        elsif mapped_record_form_fields[container].include?(field)
          # Process the field value, which will assign the value to the record
          processor.process(field, value)
        else
          raise unknown_field_error(definition)
        end
      rescue StandardError => e
        err_with_context = "Error processing field '#{container}.#{field}': #{e.message}"
        Sentry.capture_exception(StandardError.new(err_with_context))
        raise $ERROR_INFO, err_with_context, $ERROR_INFO.backtrace
      end
    end

    # Iterate through each container (record type) to apply metadata and information dates
    hud_values_by_container.keys.each do |container|
      processor = container_processor(container)

      # If this is an assessment and all fields pertaining to this record type were hidden,
      # the related record should be destroyed. (For example, a Custom Assessment that conditionally creates a CE Event).
      if custom_assessment? && containers_with_all_fields_hidden.include?(container) && processor.dependent_destroyable?
        processor.destroy_record
      else
        # This related record will be created or updated, so assign the metadata and information date.
        processor&.assign_metadata
        processor&.information_date(owner.assessment_date) if custom_assessment?
      end
    end

    owner.enrollment = enrollment_factory if owner.is_a?(Hmis::Hud::CustomAssessment)
  end

  # Transforms
  # { 'HealthAndDv.field1' => nil, 'IncomeBenefit.field1' => 3, 'IncomeBenefit.field2' => 4}
  # into =>
  # { 'HealthAndDv' => { 'field1' => nil }, 'IncomeBenefit' => { 'field1' => 3, 'field2' => 4 } }
  def hud_values_by_container
    @hud_values_by_container ||= {}.tap do |result|
      hud_values.each do |key, value|
        container, field_name = parse_key(key)
        result[container] ||= {}
        result[container].merge!({ field_name => value })
      end
    end
  end

  # Containers where all the fields for it are hidden. This would indicate
  # that it's a conditionally collected record on the assessment.
  def containers_with_all_fields_hidden
    @containers_with_all_fields_hidden ||= hud_values_by_container.select do |_, value_hash|
      value_hash.all? { |_, v| v == Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE }
    end.keys.to_set
  end

  def parse_key(key)
    # Key format is "Enrollment.entryDate", or simply "projectType" (in which case the container is the owner type ("Project") )
    if key.include?('.')
      container, field = key.split('.', 2)
    else
      container = owner_container_name
      field = key
    end

    [container, field]
  end

  def owner_container_name
    @owner_container_name ||= case owner
    when Hmis::Hud::Assessment
      'CeAssessment' # special case since the container name and class name don't match
    else
      owner.class.name.demodulize
    end
  end

  def ce_assessment?
    ce_assessment&.assessment_level.in?([1, 2])
  end

  def store_assessment_questions!
    return unless custom_assessment? && ce_assessment?

    # Queue up job to store CE Assessment responses in the HUD CE AssessmentQuestions table
    # Rspec test isolation interferes with delayed job transaction
    if Rails.env.test?
      ::Hmis::AssessmentQuestionsJob.perform_now(custom_assessment_ids: owner_id)
    else
      ::Hmis::AssessmentQuestionsJob.perform_later(custom_assessment_ids: owner_id)
    end
  end

  def owner_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    owner
  end

  def current_living_situation_factory(create: true)
    # If this is a form just for collecting CLS, it is the owner
    return owner if owner.is_a? Hmis::Hud::CurrentLivingSituation

    return current_living_situation if current_living_situation.present? || !create

    self.current_living_situation = enrollment_factory.current_living_situations.build
  end

  def service_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    @service_factory ||= owner if owner.is_a?(Hmis::Hud::Service) || owner.is_a?(Hmis::Hud::CustomService)
  end

  # Type Factories

  # Enrollment is a special case, because it is not referenced by the FormProcessor.
  # Enrollment can be the owner, or it can be related to the owner.
  # Examples of forms that may update Enrollment:
  #  - set EntryDate from intake assessment (owner_type=CustomAssessment)
  #  - enroll an existing client (owner_type=Enrollment)
  #  - update Move-in Date at occurrence (owner_type=Enrollment)
  #
  # In some other cases, the enrollment_factory is used to determine the relationship between records.
  # An example is a CustomCaseNote form that generates a CurrentLivingSituation. The form does not update Enrollment directly,
  # but it relies on the enrollment_factory to determine which enrollment to use when generating a new CLS (current_living_situation_factory)
  def enrollment_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    @enrollment_factory ||= case owner
    when Hmis::Hud::CustomAssessment
      owner.enrollment
    when Hmis::Hud::Enrollment
      owner
    else
      # This is importantly mirrored in SubmitForm which saves the `record.enrollment` if it exists
      owner.enrollment if owner.respond_to?(:enrollment)
    end
  end

  def client_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    @client_factory ||= case owner
    when Hmis::Hud::Client
      owner
    when Hmis::Hud::Enrollment
      # An 'enrollment form' can create a new client.
      # If building a new client, we need to set personal ID here
      # (rather than in ensure_id validation hook) so that it gets set
      # correctly as the Enrollment.personal_id too.
      owner.client || owner.build_client(personal_id: Hmis::Hud::Base.generate_uuid)
    when Hmis::Hud::CustomAssessment
      # An assessment can modify the client that it's associated with
      owner.client
    when HmisExternalApis::ExternalForms::FormSubmission
      # External forms can create new clients, such as PIT
      owner.enrollment.client || owner.enrollment.build_client(personal_id: Hmis::Hud::Base.generate_uuid)
    end
  end

  # Common HUD Assessment-related attributes
  def common_attributes
    data_collection_stage = owner.data_collection_stage if owner.respond_to?(:data_collection_stage)
    personal_id = owner.personal_id if owner.respond_to?(:personal_id)
    information_date = owner.information_date if owner.respond_to?(:information_date)
    {
      data_collection_stage: data_collection_stage,
      personal_id: personal_id,
      information_date: information_date,
    }
  end

  def exit_factory(create: true)
    return self.exit if self.exit.present? || !create

    if enrollment_factory.exit.present?
      # Enrollment already has an Exit that's not tied to this processor (could occur in imported data..)
      self.exit = enrollment_factory.exit
    else
      self.exit = enrollment_factory.build_exit
    end
  end

  def ce_assessment_factory(create: true)
    return owner if owner.is_a? Hmis::Hud::Assessment

    return ce_assessment if ce_assessment.present? || !create

    self.ce_assessment = enrollment_factory.assessments.build
  end

  def ce_event_factory(create: true)
    return owner if owner.is_a? Hmis::Hud::Event

    return ce_event if ce_event.present? || !create

    self.ce_event = enrollment_factory.events.build
  end

  def health_and_dv_factory(create: true)
    return health_and_dv if health_and_dv.present? || !create

    self.health_and_dv = enrollment_factory.health_and_dvs.
      build(**common_attributes)
  end

  def income_benefit_factory(create: true)
    return income_benefit if income_benefit.present? || !create

    self.income_benefit = enrollment_factory.income_benefits.
      build(**common_attributes)
  end

  def physical_disability_factory(create: true)
    return physical_disability if physical_disability.present? || !create

    self.physical_disability = enrollment_factory.disabilities.
      build(
        disability_type: 5, # Physical Disability
        **common_attributes,
      )
  end

  def developmental_disability_factory(create: true)
    return developmental_disability if developmental_disability.present? || !create

    self.developmental_disability = enrollment_factory.disabilities.
      build(
        disability_type: 6, # Developmental Disability
        **common_attributes,
      )
  end

  def chronic_health_condition_factory(create: true)
    return chronic_health_condition if chronic_health_condition.present? || !create

    self.chronic_health_condition = enrollment_factory.disabilities.
      build(
        disability_type: 7, # Chronic health condition
        **common_attributes,
      )
  end

  def hiv_aids_factory(create: true)
    return hiv_aids if hiv_aids.present? || !create

    self.hiv_aids = enrollment_factory.disabilities.
      build(
        disability_type: 8, # HIV/AIDS
        **common_attributes,
      )
  end

  def mental_health_disorder_factory(create: true)
    return mental_health_disorder if mental_health_disorder.present? || !create

    self.mental_health_disorder = enrollment_factory.disabilities.
      build(
        disability_type: 9, # Mental health disorder
        **common_attributes,
      )
  end

  def substance_use_disorder_factory(create: true)
    return substance_use_disorder if substance_use_disorder.present? || !create

    self.substance_use_disorder = enrollment_factory.disabilities.
      build(
        disability_type: 10, # Substance use disorder
        **common_attributes,
      )
  end

  def youth_education_status_factory(create: true)
    return youth_education_status if youth_education_status.present? || !create

    self.youth_education_status = enrollment_factory.youth_education_statuses.
      build(**common_attributes)
  end

  def employment_education_factory(create: true)
    return employment_education if employment_education.present? || !create

    self.employment_education = enrollment_factory.employment_educations.
      build(**common_attributes)
  end

  private def container_processor(container)
    container = container.to_sym

    if !container.in?(valid_containers.keys)
      message = "invalid container \"#{container}\" for Hmis::FormProcessor##{id}"
      raise message if Rails.env.development? || Rails.env.test?

      Sentry.capture_message(message)
      return
    end

    @container_processors ||= {}
    @container_processors[container] ||= valid_containers[container].new(self)
  end

  private def valid_containers
    @valid_containers ||= {
      # Assessment-related records
      DisabilityGroup: Hmis::Hud::Processors::DisabilityGroupProcessor,
      Enrollment: Hmis::Hud::Processors::EnrollmentProcessor,
      HealthAndDv: Hmis::Hud::Processors::HealthAndDvProcessor,
      IncomeBenefit: Hmis::Hud::Processors::IncomeBenefitProcessor,
      Exit: Hmis::Hud::Processors::ExitProcessor,
      # Form Records
      Client: Hmis::Hud::Processors::ClientProcessor,
      Service: Hmis::Hud::Processors::ServiceProcessor,
      CustomService: Hmis::Hud::Processors::ServiceProcessor,
      Organization: Hmis::Hud::Processors::OrganizationProcessor,
      Project: Hmis::Hud::Processors::ProjectProcessor,
      Inventory: Hmis::Hud::Processors::InventoryProcessor,
      ProjectCoc: Hmis::Hud::Processors::ProjectCoCProcessor,
      Funder: Hmis::Hud::Processors::FunderProcessor,
      CeParticipation: Hmis::Hud::Processors::CeParticipationProcessor,
      CustomAssessment: Hmis::Hud::Processors::CustomAssessmentProcessor,
      HmisParticipation: Hmis::Hud::Processors::HmisParticipationProcessor,
      File: Hmis::Hud::Processors::FileProcessor,
      ReferralRequest: Hmis::Hud::Processors::ReferralRequestProcessor,
      ReferralPosting: Hmis::Hud::Processors::ReferralPostingProcessor,
      YouthEducationStatus: Hmis::Hud::Processors::YouthEducationStatusProcessor,
      EmploymentEducation: Hmis::Hud::Processors::EmploymentEducationProcessor,
      CurrentLivingSituation: Hmis::Hud::Processors::CurrentLivingSituationProcessor,
      CeAssessment: Hmis::Hud::Processors::CeAssessmentProcessor,
      Event: Hmis::Hud::Processors::CeEventProcessor,
      CustomCaseNote: Hmis::Hud::Processors::CustomCaseNoteProcessor,
      # External forms
      FormSubmission: Hmis::Hud::Processors::ExternalFormSubmissionProcessor,
    }.freeze
  end

  private def all_factories
    [
      :enrollment_factory,
      :health_and_dv_factory,
      :income_benefit_factory,
      :physical_disability_factory,
      :developmental_disability_factory,
      :chronic_health_condition_factory,
      :ce_assessment_factory,
      :ce_event_factory,
      :hiv_aids_factory,
      :mental_health_disorder_factory,
      :substance_use_disorder_factory,
      :exit_factory,
      :owner_factory,
      :service_factory,
      :current_living_situation_factory,
      :youth_education_status_factory,
      :employment_education_factory,
    ]
  end

  # Pull up any errors from the HMIS records
  private def hmis_records_are_valid
    all_factories.excluding(:owner_factory).each do |factory_method|
      record = send(factory_method, create: false)
      next unless record.present?
      next if record.valid?

      errors.merge!(record.errors)
    end
  end

  # All related records to validate. This includes the Enrollment record if present.
  private def related_records
    all_factories.map do |factory_method|
      record = send(factory_method, create: false)
      # assessment is not considered a related record, other "owners" are
      next if record.is_a?(Hmis::Hud::CustomAssessment)

      record
    end.compact.uniq
  end

  def destroy_related_records!
    [
      :health_and_dv,
      :income_benefit,
      :physical_disability,
      :developmental_disability,
      :chronic_health_condition,
      :hiv_aids,
      :mental_health_disorder,
      :substance_use_disorder,
      :exit,
      :youth_education_status,
      :employment_education,
      :current_living_situation,
      :ce_assessment,
      :ce_event,
    ].each { |assoc| send(assoc)&.destroy! }.compact
  end

  # Pull out the Assessment Date from the values hash
  def find_assessment_date_from_values
    item = definition&.assessment_date_item
    return nil unless item.present? && values.present?

    date_string = values[item.link_id]
    return nil unless date_string.present?

    HmisUtil::Dates.safe_parse_date(date_string: date_string)
  end

  # Get HmisError::Errors object containing related record AR errors that can be resolved
  # as GraphQL ValidationErrors.
  def collect_active_record_errors
    errors = HmisErrors::Errors.new
    related_records.each do |record|
      next if record.errors.none?

      ar_errors = record.errors.errors.reject do |e|
        # Skip validations for ID fields
        if e.attribute.to_s.underscore.ends_with?('_id')
          true # reject
        # Skip validations for relation fields ("Income Benefit is invalid" on the Enrollment)
        elsif record.respond_to?(e.attribute) && record.send(e.attribute).is_a?(ActiveRecord::Relation)
          true # reject
        # Skip validations for Information Date if this is an assessment,
        # since we validate the assessment date separately using CustomAssessmentValidator
        elsif custom_assessment? && e.attribute.to_s.underscore == 'information_date'
          true # reject
        else
          false
        end
      end
      errors.add_ar_errors(ar_errors)
    end

    errors
  end

  # Validate `values` purely based on FormDefinition validation requirements
  # @return [HmisError::Error] an array errors
  def collect_form_validations
    definition.validate_form_values(values)
  end

  # Validate related records using custom AR Validators
  # @return [HmisError::Error] an array errors
  def collect_record_validations(user: nil, household_members: nil)
    # Collect ActiveRecord validations (as HmisErrors)
    errors = collect_active_record_errors
    # Collect validations on the Assessment Date (if this is an assessment form)
    if custom_assessment?
      errors.push(*Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(
        owner, # CustomAssessment record
        # Need to pass household members so we can validate based on their unpersisted entry/exit dates
        household_members: household_members,
      ))
    end

    # Collect errors from custom validator, in the context of this role
    # TODO: remove this and switch to using validation contexts instead.
    # This works OK for assessments, but not other types of forms. For example for
    # an Enrollment form that creates/edits Client, this will NOT run he Client validator.
    role = definition&.role
    related_records.each do |record|
      validator = record.class.validators.find { |v| v.is_a?(Hmis::Hud::Validators::BaseValidator) }&.class
      errors.push(*validator.hmis_validate(record, user: user, role: role)) if validator.present?
    end

    errors.errors
  end

  private def translate_field(field, container: nil)
    camelized = field.to_s.camelize(:lower)
    containerize(container, camelized)
  end

  private def translate_disability_field(context, field, container: nil)
    return containerize(container, field) if field == 'disability_response'

    camelized = "#{context}#{field.to_s.camelize}"
    containerize(container, camelized)
  end

  private def containerize(container, field)
    return field unless container.present?

    "#{container}.#{field}"
  end

  # @return <Hash{container_name=> Set<fields> }>
  private def mapped_record_form_fields
    @mapped_record_form_fields ||= begin
      result = Hash.new { |hash, key| hash[key] = Set.new }
      definition.link_id_item_hash.each_value do |item|
        mapping = item.mapping
        next unless mapping&.field_name

        container_name = mapping_container_name(mapping)
        result[container_name].add(mapping.field_name)
      end
      result
    end
  end

  # @return <Hash{container_name=> Set<fields> }>
  private def mapped_custom_form_fields
    @mapped_custom_form_fields ||= begin
      result = Hash.new { |hash, key| hash[key] = Set.new }
      definition.link_id_item_hash.each_value do |item|
        mapping = item.mapping
        next unless mapping&.custom_field_key

        container_name = mapping_container_name(mapping)
        result[container_name].add(mapping.custom_field_key)
      end
      result
    end
  end

  # convert the record_type to a "container name" that matches the form processor names
  private def mapping_container_name(mapping)
    if mapping.record_type
      record_type = Hmis::Form::RecordType.find(mapping.record_type)
      raise "Invalid record type '#{mapping.record_type}'" unless record_type

      record_type.processor_name
    else
      owner_container_name
    end
  end
end
