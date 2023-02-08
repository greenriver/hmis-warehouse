###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::AssessmentProcessor < ::GrdaWarehouseBase
  self.table_name = :hmis_assessment_processors

  has_one :assessment_detail

  # assessment is accessed through the assessment_detail
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

  def run!
    return unless assessment_detail.hud_values.present?

    assessment_detail.hud_values.each do |key, value|
      # Don't use greedy matching so that the container is up to the first dot, and the rest is the field
      match = /(.*?)\.(.*)/.match(key)
      next unless match.present?

      container, field = match[1..2]

      begin
        container_processor(container)&.process(field, value)
      rescue StandardError => e
        raise e.class, "Error processing field '#{field}': #{e.message}"
      end
    end

    valid_containers.values.each do |processor|
      processor.new(self).information_date(assessment_detail.assessment.assessment_date)
    end
  end

  # Type Factories
  def enrollment_factory(create: true) # rubocop:disable Lint/UnusedMethodArgument
    # The enrollment has already been created, so we can just return it
    assessment_detail.assessment.enrollment
  end

  def common_attributes
    {
      data_collection_stage: assessment_detail.data_collection_stage,
      personal_id: enrollment_factory.client.personal_id,
      information_date: assessment_detail.assessment.assessment_date,
      user_id: assessment_detail.assessment.user_id,
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

    self.exit = enrollment_factory.build_exit(
      personal_id: enrollment_factory.client.personal_id,
      user_id: assessment_detail.assessment.user_id,
      exit_date: assessment_detail.assessment.assessment_date,
    )
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
      DisabilityGroup: Hmis::Hud::Processors::DisabilityGroupProcessor,
      Enrollment: Hmis::Hud::Processors::EnrollmentProcessor,
      EnrollmentCoc: Hmis::Hud::Processors::EnrollmentCocProcessor,
      HealthAndDv: Hmis::Hud::Processors::HealthAndDvProcessor,
      IncomeBenefit: Hmis::Hud::Processors::IncomeBenefitProcessor,
      Exit: Hmis::Hud::Processors::ExitProcessor,
    }.freeze
  end

  # Pull up and errors from the HMIS records, adjusting their attribute names as required
  private def hmis_records_are_valid
    {
      enrollment_coc_factory: ->(attribute_name) { translate_field(attribute_name) },
      health_and_dv_factory: ->(attribute_name) { translate_field(attribute_name) },
      income_benefit_factory: ->(attribute_name) { translate_field(attribute_name) },
      physical_disability_factory: ->(attribute_name) { translate_disability_field('physicalDisability', attribute_name) },
      developmental_disability_factory: ->(attribute_name) { translate_disability_field('developmentalDisability', attribute_name) },
      chronic_health_condition_factory: ->(attribute_name) { translate_disability_field('chronicHealthCondition', attribute_name) },
      hiv_aids_factory: ->(attribute_name) { translate_disability_field('hivAids', attribute_name) },
      mental_health_disorder_factory: ->(attribute_name) { translate_disability_field('mentalHealthDisorder', attribute_name) },
      substance_use_disorder_factory: ->(attribute_name) { translate_disability_field('substanceUseDisorder', attribute_name) },
      exit_factory: ->(attribute_name) { translate_field(attribute_name) },
    }.each do |factory_method, transformer|
      record = send(factory_method, create: false)
      next unless record.present?
      next if record.valid?

      record.errors.each do |error|
        errors.add(transformer.call(error.attribute), error.message, **error.options)
      end
    end
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
