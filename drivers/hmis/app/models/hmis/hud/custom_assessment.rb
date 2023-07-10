###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A CustomAssessment record represents an assessment that has been performed.
# It may be a HUD assessment (intake, exit, etc) or a fully custom assessment.

# Assessments can be WIP (aka incomplete) or Submitted.
# Assessments are "processed" using the FormProcessor, which maintains references
# to all related records that have been created/updated from the assessment
# if it has been submitted.
class Hmis::Hud::CustomAssessment < Hmis::Hud::Base
  self.table_name = :CustomAssessments
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

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

  scope :in_progress, -> { where(wip: true) }
  scope :not_in_progress, -> { where(wip: false) }
  scope :intakes, -> { where(data_collection_stage: 1) }
  scope :exits, -> { where(data_collection_stage: 3) }

  scope :with_role, ->(role) do
    stages = Array.wrap(role).map { |r| Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[r.to_sym] }.compact
    where(data_collection_stage: stages)
  end

  scope :with_project_type, ->(project_types) do
    joins(:project).merge(Hmis::Hud::Project.with_project_type(project_types))
  end

  scope :with_project, ->(project_ids) do
    joins(:project).merge(Hmis::Hud::Project.where(id: project_ids))
  end

  scope :for_enrollments, ->(enrollments) do
    joins(:enrollment).merge(enrollments)
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
    self.wip = true
    save!
  end

  def save_not_in_progress
    self.wip = false
    save!
  end

  def in_progress?
    wip
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
    raise HmisErrors::ApiError, 'Assessment not in household' if source_assessment.present? && !household_enrollments.pluck(:enrollment_id).include?(source_assessment.enrollment_id)

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
