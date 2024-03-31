###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomAssessment" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv
# "CustomAssessment" is not to be confused with "Assessment" which IS a HUD defined record type

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
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  # a better name would be "form_definition"
  belongs_to :definition, primary_key: 'identifier', foreign_key: 'form_definition_identifier', class_name: 'Hmis::Form::Definition', optional: true

  has_one :form_processor, class_name: 'Hmis::Form::FormProcessor', dependent: :destroy
  has_one :health_and_dv, through: :form_processor
  has_one :income_benefit, through: :form_processor
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
  has_one :ce_assessment, through: :form_processor
  has_one :ce_event, through: :form_processor

  # Alias fields that are not part of the Assessment schema
  alias_to_underscore [:DataCollectionStage]

  attr_accessor :in_progress

  validates_with Hmis::Hud::Validators::CustomAssessmentValidator
  validate :form_processor_is_valid, on: :form_submission

  scope :in_progress, -> { where(wip: true) }
  scope :not_in_progress, -> { where(wip: false) }
  scope :intakes, -> { where(data_collection_stage: 1) }
  scope :exits, -> { where(data_collection_stage: 3) }
  scope :updates, -> { where(data_collection_stage: 2) }
  scope :annuals, -> { where(data_collection_stage: 5) }
  scope :post_exits, -> { where(data_collection_stage: 6) }

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
    touch # Update even if no changes to assessment record
  end

  def save_not_in_progress
    self.wip = false
    save!
    touch # Update even if no changes to assessment record
  end

  def in_progress?
    wip
  end

  def hud_assessment?
    HudUtility2024.data_collection_stages.keys.include?(data_collection_stage)
  end

  def intake?
    data_collection_stage == 1
  end

  def post_exit?
    data_collection_stage == 6
  end

  def exit?
    data_collection_stage == 3
  end

  def annual?
    data_collection_stage == 5
  end

  def update?
    data_collection_stage == 2
  end

  def title
    title = HudUtility2024.assessment_name_by_data_collection_stage[data_collection_stage]
    title || definition&.title.presence || 'Custom Assessment'
  end

  def save_submitted_assessment!(current_user:, as_wip: false)
    Hmis::Hud::CustomAssessment.transaction do
      # Save FormProcessor to save wip values and/or related records
      form_processor.save! # Not passing validation context because records have already been validated

      # Save the assessment record
      if as_wip
        save_in_progress
      else
        save_not_in_progress
        form_processor.store_assessment_questions! if form_processor.ce_assessment?
      end

      unless as_wip
        # Save the Enrollment (not saved by FormProcessor because they dont have a relationship)
        enrollment.save!
        enrollment.touch # Update even if no changes to Enrollment
        # Move Enrollment out of WIP if this is a submitted intake
        enrollment.save_not_in_progress! if intake?
        # If this is an exit, release the unit
        enrollment.release_unit!(enrollment.exit_date, user: current_user) if exit?
        # Accept referral in LINK if submitted intake (HoH)
        enrollment.accept_referral!(current_user: current_user) if intake?
        # Close referral in LINK if submitted exit (HoH)
        enrollment.close_referral!(current_user: current_user) if exit?
      end
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::AssessmentFilter.new(input).filter_scope(self)
  end

  def self.new_with_defaults(enrollment:, user:, form_definition:, assessment_date: nil)
    new_assessment = new(
      user_id: user.user_id,
      assessment_date: assessment_date,
      data_collection_stage: Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[form_definition.role.to_sym] || 99,
      form_definition_identifier: form_definition.identifier,
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

    household_assessments = Hmis::Hud::CustomAssessment.with_role(assessment_role.to_sym).
      where(enrollment_id: household_enrollments.pluck(:enrollment_id), data_source_id: household_enrollments.pluck(:data_source_id))

    threshold_in_days = threshold.to_i / 86400 # to_i always returns seconds

    case assessment_role.to_sym
    when :INTAKE, :EXIT
      # Ensure we only return 1 assessment per enrollment
      household_assessments.index_by(&:enrollment_id).values
    when :ANNUAL
      # If we have a source, find annuals "near" it (within threshold)
      # If we don't have a source, that means this is a new annual. Include any annuals from the past 3 months.
      source_date = source_assessment&.assessment_date || Date.current
      household_assessments.group_by(&:enrollment_id).
        map do |_, assmts|
          nearest_assmt = assmts.min_by { |a| (source_date - a.assessment_date).abs }
          distance_in_days = (source_date - nearest_assmt.assessment_date).to_i.abs

          nearest_assmt if distance_in_days <= threshold_in_days
        end.compact
    else
      raise HmisErrors::ApiError, "Unable to group #{assessment_role} assessments"
    end
  end

  def self.hud_key
    :CustomAssessmentID
  end

  # If we are validating a form submission, validate the form processor
  # which will validate all related records.
  # Does not merge errors into assessment error object, so caller
  # must check form_processor.errors for any validation errors.
  private def form_processor_is_valid
    form_processor.valid?(:form_submission)
  end

  def deletion_would_cause_conflicting_enrollments?
    return false if in_progress?

    exit? && enrollment.client.enrollments.
      where(data_source: enrollment.data_source, project_id: enrollment.project_id).
      where.not(id: enrollment.id).
      where(e_t[:entry_date].gteq(enrollment.entry_date)).
      any?
  end
end
