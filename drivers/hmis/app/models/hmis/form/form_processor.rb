###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::FormProcessor < ::GrdaWarehouseBase
  self.table_name = :hmis_form_processors

  has_one :custom_form

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

  validate :hmis_records_are_valid

  attr_accessor :owner

  def run!(owner:)
    # Set the owner reference so we are updating the correct record. Unpersisted changes can't be validated correctly if you go through custom_form.owner.
    self.owner = owner
    return unless custom_form.hud_values.present?

    custom_form.hud_values.each do |key, value|
      # Don't use greedy matching so that the container is up to the first dot, and the rest is the field
      match = /(.*?)\.(.*)/.match(key)
      if match.present?
        # Key format is "Enrollment.entryDate"
        container, field = match[1..2]
      else
        # Key format is "projectType", and the container is the owner type ("Project")
        container = owner.class.name.demodulize
        field = key
      end

      begin
        container_processor(container)&.process(field, value)
      rescue StandardError => e
        raise $!, "Error processing field '#{field}': #{e.message}", $!.backtrace
      end
    end

    valid_containers.values.each do |processor|
      processor.new(self).information_date(custom_form.assessment.assessment_date) if custom_form.assessment.present?
    end

    owner.enrollment = enrollment_factory if owner.is_a?(Hmis::Hud::CustomAssessment)
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
    @enrollment_factory ||= owner.enrollment if owner.is_a?(Hmis::Hud::CustomAssessment)
  end

  def common_attributes
    {
      data_collection_stage: custom_form.assessment.data_collection_stage,
      personal_id: custom_form.assessment.personal_id,
      information_date: custom_form.assessment.assessment_date,
      user_id: custom_form.assessment.user_id,
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
        user_id: custom_form.assessment.user_id,
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

  # Get HmisError::Errors object containing related record AR errors that can be resolved
  # as GraphQL ValidationErrors.
  def collect_active_record_errors
    errors = HmisErrors::Errors.new
    related_records.each do |record|
      next if record.errors.none?

      # Skip relation fields, to avoid errors like "Income Benefit is invalid" on the Enrollment
      ar_errors = record.errors.errors.reject do |e|
        e.attribute.to_s.underscore.ends_with?('_id') || record.send(e.attribute).is_a?(ActiveRecord::Relation)
      end
      errors.add_ar_errors(ar_errors)
    end

    errors
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
