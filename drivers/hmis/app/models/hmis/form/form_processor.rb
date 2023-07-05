###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::FormProcessor < ::GrdaWarehouseBase
  self.table_name = :hmis_form_processors

  # The assessment that was processed with this processor.
  # If processor is being used as in-memory processor for records, this will be empty.
  belongs_to :custom_assessment, class_name: 'Hmis::Hud::CustomAssessment', optional: false
  # Definition that was most recently used to process this assessment
  belongs_to :definition, class_name: 'Hmis::Form::Definition', optional: true

  # Related records that were created/updated from this assessment
  belongs_to :health_and_dv, class_name: 'Hmis::Hud::HealthAndDv', optional: true, autosave: true
  belongs_to :income_benefit, class_name: 'Hmis::Hud::IncomeBenefit', optional: true, autosave: true
  belongs_to :enrollment_coc, class_name: 'Hmis::Hud::EnrollmentCoc', optional: true, autosave: true
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

  validate :hmis_records_are_valid

  attr_accessor :owner, :hud_user, :current_user

  def run!(owner:, user:)
    # Owner is the "base" record for the form, which could be an assessment, client, project, etc.
    self.owner = owner
    # Set the HUD User and current user, so processors can store them on related records
    self.current_user = user
    self.hud_user = Hmis::Hud::User.from_user(user)

    return unless hud_values.present?

    # Iterate through each hud_value, processing field-by-field
    hud_values.each do |key, value|
      container, field = parse_key(key)
      # If this key can be identified as a CustomDataElement, set it and continue
      next if container_processor(container)&.process_custom_field(field, value)

      begin
        container_processor(container)&.process(field, value)
      rescue StandardError => e
        Sentry.capture_exception(e)
        raise $ERROR_INFO, "Error processing field '#{field}': #{e.message}", $ERROR_INFO.backtrace
      end
    end

    # Iterate through each used processor to apply metadata and information dates
    relevant_container_names = hud_values.keys.map { |k| parse_key(k)&.first }.compact.uniq
    relevant_container_names.each do |container|
      container_processor(container)&.assign_metadata
      container_processor(container)&.information_date(custom_assessment.assessment_date) if custom_assessment.present?
    end

    owner.enrollment = enrollment_factory if owner.is_a?(Hmis::Hud::CustomAssessment)
  end

  def parse_key(key)
    # Key format is "Enrollment.entryDate", or simply "projectType" (in which case the container is the owner type ("Project") )
    if key.include?('.')
      container, field = key.split('.', 2)
    else
      container = owner.class.name.demodulize
      field = key
    end

    [container, field]
  end

  def owner_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    owner
  end

  def service_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    @service_factory ||= owner.owner if owner.is_a? Hmis::Hud::HmisService
  end

  # Type Factories
  def enrollment_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    # The enrollment has already been created, so we can just return it
    @enrollment_factory ||= case owner
    when Hmis::Hud::CustomAssessment
      owner.enrollment
    when Hmis::Hud::Enrollment
      owner
    end
  end

  def common_attributes
    {
      data_collection_stage: custom_assessment&.data_collection_stage,
      personal_id: custom_assessment&.personal_id,
      information_date: custom_assessment&.assessment_date,
    }
  end

  # The items associated with the enrollments are all singletons, so return
  # them if they already exist, otherwise create them
  def enrollment_coc_factory(create: true)
    return enrollment_coc if enrollment_coc.present? || !create

    self.enrollment_coc = enrollment_factory.enrollment_cocs.
      build(
        household_id: enrollment_factory.household_id,
        project_id: enrollment_factory.project_id,
        **common_attributes,
      )
  end

  def exit_factory(create: true)
    return self.exit if self.exit.present? || !create

    if enrollment_factory.exit.present?
      # Enrollment already has an Exit that's not tied to this processor (could occur in imported data..)
      self.exit = enrollment_factory.exit
    else
      self.exit = enrollment_factory.build_exit(
        personal_id: enrollment_factory.client.personal_id,
        user_id: custom_assessment&.user_id,
      )
    end
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

  private def container_processor(container)
    container = container.to_sym
    return unless container.in?(valid_containers.keys)

    @container_processors ||= {}
    @container_processors[container] ||= valid_containers[container].new(self)
  end

  private def valid_containers
    @valid_containers ||= {
      # Assessment-related records
      DisabilityGroup: Hmis::Hud::Processors::DisabilityGroupProcessor,
      Enrollment: Hmis::Hud::Processors::EnrollmentProcessor,
      EnrollmentCoc: Hmis::Hud::Processors::EnrollmentCocProcessor,
      HealthAndDv: Hmis::Hud::Processors::HealthAndDvProcessor,
      IncomeBenefit: Hmis::Hud::Processors::IncomeBenefitProcessor,
      Exit: Hmis::Hud::Processors::ExitProcessor,
      # Form Records
      Client: Hmis::Hud::Processors::ClientProcessor,
      HmisService: Hmis::Hud::Processors::ServiceProcessor,
      Organization: Hmis::Hud::Processors::OrganizationProcessor,
      Project: Hmis::Hud::Processors::ProjectProcessor,
      Inventory: Hmis::Hud::Processors::InventoryProcessor,
      ProjectCoc: Hmis::Hud::Processors::ProjectCoCProcessor,
      Funder: Hmis::Hud::Processors::FunderProcessor,
      File: Hmis::Hud::Processors::FileProcessor,
      ReferralRequest: Hmis::Hud::Processors::ReferralRequestProcessor,
    }.freeze
  end

  private def all_factories
    [
      :enrollment_factory,
      :enrollment_coc_factory,
      :health_and_dv_factory,
      :income_benefit_factory,
      :physical_disability_factory,
      :developmental_disability_factory,
      :chronic_health_condition_factory,
      :hiv_aids_factory,
      :mental_health_disorder_factory,
      :substance_use_disorder_factory,
      :exit_factory,
      :owner_factory,
      :service_factory,
    ]
  end

  # Pull up any errors from the HMIS records
  private def hmis_records_are_valid
    all_factories.excluding(:owner_factory, :service_factory).each do |factory_method|
      record = send(factory_method, create: false)
      next unless record.present?
      next if record.valid?

      errors.merge!(record.errors)
    end
  end

  def related_records
    all_factories.map do |factory_method|
      record = send(factory_method, create: false)
      # assessment is not considered a related record, other "owners" are
      next if record.is_a?(Hmis::Hud::CustomAssessment)

      record
    end.compact.uniq
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

      # Skip relation fields, to avoid errors like "Income Benefit is invalid" on the Enrollment
      ar_errors = record.errors.errors.reject do |e|
        e.attribute.to_s.underscore.ends_with?('_id') || (record.respond_to?(e.attribute) && record.send(e.attribute).is_a?(ActiveRecord::Relation))
      end
      errors.add_ar_errors(ar_errors)
    end

    errors
  end

  # Validate related records using custom AR Validators
  # @return [HmisError::Error] an array errors
  def collect_record_validations(user: nil, household_members: nil)
    # Collect ActiveRecord validations (as HmisErrors)
    errors = collect_active_record_errors
    # Collect validations on the Assessment Date (if this is an assessment form)
    if custom_assessment.present?
      errors.push(*Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(
        custom_assessment,
        # Need to pass household members so we can validate based on their unpersisted entry/exit dates
        household_members: household_members,
      ))
    end

    # Collect errors from custom validator, in the context of this role
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
end
