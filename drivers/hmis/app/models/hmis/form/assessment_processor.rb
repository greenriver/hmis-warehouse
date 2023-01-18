###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::AssessmentProcessor < ::GrdaWarehouseBase
  self.table_name = :hmis_assessment_processors

  has_one :assessment_detail

  # assessment is accessed through the assessment_detail
  belongs_to :health_and_dv, class_name: 'Hmis::Hud::HealthAndDv', optional: true
  belongs_to :income_benefit, class_name: 'Hmis::Hud::IncomeBenefit', optional: true
  belongs_to :enrollment_coc, class_name: 'Hmis::Hud::EnrollmentCoc', optional: true
  belongs_to :physical_disability, class_name: 'Hmis::Hud::Disability', optional: true
  belongs_to :developmental_disability, class_name: 'Hmis::Hud::Disability', optional: true
  belongs_to :chronic_health_condition, class_name: 'Hmis::Hud::Disability', optional: true
  belongs_to :hiv_aids, class_name: 'Hmis::Hud::Disability', optional: true
  belongs_to :mental_health_disorder, class_name: 'Hmis::Hud::Disability', optional: true
  belongs_to :substance_use_disorder, class_name: 'Hmis::Hud::Disability', optional: true

  def run!
    return unless assessment_detail.hud_values.present?

    assessment_detail.hud_values.each do |key, value|
      # Don't use greedy matching so that the container is up to the first dot, and the rest is the field
      container, field = /(.*?)\.(.*)/.match(key)[1..2]

      container_processor(container)&.process(field, value)
    end
  end

  # Type Factories
  def enrollment_factory
    # The enrollment has already been created, so we can just return it
    assessment_detail.assessment.enrollment
  end

  # The items associated with the enrollments are all singletons, so return
  # them if they already exist, otherwise create them
  def enrollment_coc_factory
    return enrollment_coc if enrollment_coc.present?

    self.enrollment_coc = enrollment_factory.enrollment_cocs.
      where(data_collection_stage: assessment_detail.data_collection_stage).
      first_or_initialize(
        household_id: enrollment_factory.household_id,
        project_id: enrollment_factory.project_id,
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def health_and_dv_factory
    return health_and_dv if health_and_dv.present?

    self.health_and_dv = enrollment_factory.health_and_dvs.
      where(data_collection_stage: assessment_detail.data_collection_stage).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def income_benefit_factory
    return income_benefit if income_benefit.present?

    self.income_benefit = enrollment_factory.income_benefits.
      where(data_collection_stage: assessment_detail.data_collection_stage).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def physical_disability_factory
    return physical_disability if physical_disability.present?

    self.physical_disability = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 5, # Physical Disability
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def developmental_disability_factory
    return developmental_disability if developmental_disability.present?

    self.developmental_disability = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 6, # Developmental Disability
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def chronic_health_condition_factory
    return chronic_health_condition if chronic_health_condition.present?

    self.chronic_health_condition = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 7, # Chronic health condition
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def hiv_aids_factory
    return hiv_aids if hiv_aids.present?

    self.hiv_aids = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 8, # HIV/AIDS
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def mental_health_disorder_factory
    return mental_health_disorder if mental_health_disorder.present?

    self.mental_health_disorder = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 9, # Mental health disorder
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
      )
  end

  def substance_use_disorder_factory
    return substance_use_disorder if substance_use_disorder.present?

    self.substance_use_disorder = enrollment_factory.disabilities.
      where(
        data_collection_stage: assessment_detail.data_collection_stage,
        disability_type: 10, # Substance use disorder
      ).
      first_or_initialize(
        personal_id: enrollment_factory.client.personal_id,
        information_date: assessment_detail.assessment.assessment_date,
        user_id: assessment_detail.assessment.user_id,
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
    }.freeze
  end
end
