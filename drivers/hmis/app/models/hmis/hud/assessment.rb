###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Assessment < Hmis::Hud::Base
  self.table_name = :Assessment
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ArelHelper

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze
  WIP_ID = 'WIP'.freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  has_one :assessment_detail, class_name: 'Hmis::Form::AssessmentDetail'
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :wip, class_name: 'Hmis::Wip', as: :source, dependent: :destroy

  attr_accessor :in_progress

  validates_with Hmis::Hud::Validators::AssessmentValidator

  scope :in_progress, -> { where(enrollment_id: WIP_ID) }
  scope :not_in_progress, -> { where.not(enrollment_id: WIP_ID) }

  # hide previous declaration of :viewable_by, we'll use this one
  replace_scope :viewable_by, ->(user) do
    enrollment_ids = Hmis::Hud::Enrollment.viewable_by(user).pluck(:id, :EnrollmentID)
    viewable_wip = wip_t[:enrollment_id].in(enrollment_ids.map(&:first))
    viewable_completed = as_t[:EnrollmentID].in(enrollment_ids.map(&:second))

    left_outer_joins(:wip).where(viewable_wip.or(viewable_completed))
  end

  # hide previous declaration of :editable_by, we'll use this one
  replace_scope :editable_by, ->(user) do
    enrollment_ids = Hmis::Hud::Enrollment.editable_by(user).pluck(:id, :EnrollmentID)
    editable_wip = wip_t[:enrollment_id].in(enrollment_ids.map(&:first))
    editable_completed = as_t[:EnrollmentID].in(enrollment_ids.map(&:second))

    left_outer_joins(:wip).where(editable_wip.or(editable_completed))
  end

  scope :with_role, ->(role) do
    joins(:assessment_detail).merge(Hmis::Form::AssessmentDetail.with_role(role))
  end

  def enrollment
    super || Hmis::Hud::Enrollment.find(wip.enrollment_id)
  end

  def self.generate_assessment_id
    generate_uuid
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

    self.enrollment_id = WIP_ID
    save!(validate: false)
    self.wip = Hmis::Wip.create_with(date: assessment_date).find_or_create_by(
      source: self,
      enrollment_id: saved_enrollment_id,
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
    @in_progress = enrollment_id == WIP_ID if @in_progress.nil?
    @in_progress
  end

  def intake?
    assessment_detail&.data_collection_stage == 1
  end

  def exit?
    assessment_detail&.data_collection_stage == 3
  end

  def self.new_with_defaults(enrollment:, user:, form_definition:, assessment_date: nil)
    new_assessment = new(
      data_source_id: user.data_source_id,
      user_id: user.user_id,
      personal_id: enrollment.personal_id,
      enrollment_id: enrollment.enrollment_id,
      assessment_id: Hmis::Hud::Assessment.generate_assessment_id,
      assessment_date: assessment_date,
      assessment_location: enrollment.project.project_name,
      assessment_type: ::HudUtility.ignored_enum_value,
      assessment_level: ::HudUtility.ignored_enum_value,
      prioritization_status: ::HudUtility.ignored_enum_value,
    )

    new_assessment.assessment_detail = Hmis::Form::AssessmentDetail.new(
      definition: form_definition,
      role: form_definition.role,
      data_collection_stage: Types::HmisSchema::Enums::AssessmentRole.as_data_collection_stage(form_definition.role),
      status: 'draft',
    )

    new_assessment
  end
end
