###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A CustomAssessment record represents an assessment that has been performed.
# It may be a HUD assessment (intake, exit, etc) or a fully custom assessment.

# Assessments can be WIP (aka incomplete) or Submitted.
# WIP assessments have a null EnrollmentID, and a record in the wip table.
# Assessments are "processed" using the FormProcessor, which maintains references
# to all related records that have been created/updated from the assessment.
class Hmis::Hud::CustomAssessment < Hmis::Hud::Base
  self.table_name = :CustomAssessments
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze
  WIP_ID = 'WIP'.freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment') # WIP_ID for WIP assessment
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  has_one :wip, class_name: 'Hmis::Wip', as: :source, dependent: :destroy
  has_many :custom_data_elements, as: :owner

  has_one :form_processor, class_name: 'Hmis::Form::FormProcessor', dependent: :destroy
  has_one :definition, through: :form_processor
  has_one :health_and_dv, through: :form_processor
  has_one :income_benefit, through: :form_processor
  has_one :enrollment_coc, through: :form_processor
  has_one :physical_disability, through: :form_processor
  has_one :developmental_disability, through: :form_processor
  has_one :chronic_health_condition, through: :form_processor
  has_one :hiv_aids, through: :form_processor
  has_one :mental_health_disorder, through: :form_processor
  has_one :substance_use_disorder, through: :form_processor
  has_one :exit, through: :form_processor
  has_one :youth_education_status, through: :form_processor
  has_one :employment_education, through: :form_processor
  has_one :current_living_situation, through: :form_processor

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true

  # Alias fields that are not part of the Assessment schema
  alias_to_underscore [:DataCollectionStage]

  attr_accessor :in_progress

  validates_with Hmis::Hud::Validators::CustomAssessmentValidator

  scope :in_progress, -> { where(enrollment_id: WIP_ID) }
  scope :not_in_progress, -> { where.not(enrollment_id: WIP_ID) }
  scope :intakes, -> { where(data_collection_stage: 1) }
  scope :exits, -> { where(data_collection_stage: 3) }

  # hide previous declaration of :viewable_by, we'll use this one
  replace_scope :viewable_by, ->(user) do
    enrollment_ids = Hmis::Hud::Enrollment.viewable_by(user).pluck(:id, :EnrollmentID)
    viewable_wip = wip_t[:enrollment_id].in(enrollment_ids.map(&:first))
    viewable_completed = cas_t[:EnrollmentID].in(enrollment_ids.map(&:second))

    left_outer_joins(:wip).where(viewable_wip.or(viewable_completed))
  end

  scope :with_role, ->(role) do
    stages = Array.wrap(role).map { |r| Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[r.to_sym] }.compact
    where(data_collection_stage: stages)
  end

  scope :with_project_type, ->(project_types) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project_type(project_types))
  end

  scope :with_project, ->(project_ids) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project(project_ids))
  end

  scope :for_enrollments, ->(enrollments) do
    hud_ids = enrollments.pluck(:enrollment_id)
    db_ids = enrollments.pluck(:id)
    completed_assessments = cas_t[:enrollment_id].in(hud_ids)
    wip_assessments = wip_t[:enrollment_id].in(db_ids)

    ids = Hmis::Hud::CustomAssessment.left_outer_joins(:wip).where(completed_assessments.or(wip_assessments)).pluck(:id)
    where(id: ids)
  end

  def enrollment
    super || Hmis::Hud::Enrollment.find_by(id: wip&.enrollment_id)
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :assessment_date
      order(assessment_date: :desc, date_created: :desc)
    when :date_updated
      order(date_updated: :desc)
    else
      raise NotImplementedError
    end
  end

  def save_in_progress
    saved_enrollment_id = enrollment.id
    project_id = enrollment.project.id

    self.enrollment_id = WIP_ID
    save!(validate: false)
    touch
    self.wip = Hmis::Wip.create_with(date: assessment_date).find_or_create_by(
      source: self,
      enrollment_id: saved_enrollment_id,
      project_id: project_id,
      client_id: client.id,
    )

    wip.update(date: assessment_date)
    wip
  end

  def save_not_in_progress
    transaction do
      self.enrollment_id = enrollment_id == WIP_ID ? enrollment.enrollment_id : enrollment_id
      wip&.destroy
      save!
    end
  end

  def in_progress?
    enrollment_id == WIP_ID
  end

  def intake?
    data_collection_stage == 1
  end

  def exit?
    data_collection_stage == 3
  end

  def self.apply_filters(input)
    Hmis::Filter::AssessmentFilter.new(input).filter_scope(self)
  end

  def self.new_with_defaults(enrollment:, user:, form_definition:, assessment_date: nil)
    new_assessment = new(
      user_id: user.user_id,
      assessment_date: assessment_date,
      data_collection_stage: Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[form_definition.role.to_sym] || 99,
      **enrollment.slice(:data_source_id, :personal_id, :enrollment_id),
    )
    new_assessment.build_form_processor(definition: form_definition)
    # AR doesn't recognize the built record on the has_one-through, so add it directly
    new_assessment.definition = form_definition
    new_assessment
  end

  def self.group_household_assessments(household_enrollments:, assessment_role:, threshold:, assessment_id: nil)
    source_assessment = Hmis::Hud::CustomAssessment.find(assessment_id) if assessment_id.present?
    # FIXME wont work for wip.
    # raise HmisErrors::ApiError, 'Assessment not in household' if source_assessment.present? && !enrollments.pluck(:enrollment_id).include(source_assessment.enrollment_id)

    household_assessments = Hmis::Hud::CustomAssessment.with_role(assessment_role.to_sym).for_enrollments(household_enrollments)

    case assessment_role.to_sym
    when :INTAKE, :EXIT
      # Ensure we only return 1 assessment per person
      household_assessments.index_by(&:personal_id).values
    when :ANNUAL
      # If we have a source, find annuals "near" it (within threshold)
      # If we don't have a source, that means this is a new annual. Include any annuals from the past 3 months.
      source_date = source_assessment&.assessment_date || Date.current
      household_assessments.group_by(&:personal_id).
        map do |_, assmts|
          nearest_assmt = assmts.min_by { |a| (source_date - a.assessment_date).abs }
          distance = (source_date - nearest_assmt.assessment_date).abs

          nearest_assmt if distance <= threshold
        end.compact
    else
      raise HmisErrors::ApiError, "Unable to group #{assessment_role} assessments"
    end
  end

  def self.hud_key
    :CustomAssessmentID
  end
end
