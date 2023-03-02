###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomAssessment < Hmis::Hud::Base
  self.table_name = :CustomAssessments
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include HmisArelHelper

  SORT_OPTIONS = [:assessment_date, :date_updated].freeze
  WIP_ID = 'WIP'.freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  has_one :custom_form, class_name: 'Hmis::Form::CustomForm', as: :owner, dependent: :destroy
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :wip, class_name: 'Hmis::Wip', as: :source, dependent: :destroy

  # Alias fields that are not part of the Assessment schema
  [:DataCollectionStage].each do |col|
    alias_attribute col.to_s.underscore.to_sym, col
  end

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

  # hide previous declaration of :editable_by, we'll use this one
  replace_scope :editable_by, ->(user) do
    enrollment_ids = Hmis::Hud::Enrollment.editable_by(user).pluck(:id, :EnrollmentID)
    editable_wip = wip_t[:enrollment_id].in(enrollment_ids.map(&:first))
    editable_completed = cas_t[:EnrollmentID].in(enrollment_ids.map(&:second))

    left_outer_joins(:wip).where(editable_wip.or(editable_completed))
  end

  scope :with_role, ->(role) do
    joins(:custom_form).merge(Hmis::Form::CustomForm.with_role(role))
  end

  def enrollment
    super || Hmis::Hud::Enrollment.find(wip.enrollment_id)
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
    touch
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
    data_collection_stage == 1
  end

  def exit?
    data_collection_stage == 3
  end

  def self.new_with_defaults(enrollment:, user:, form_definition:, assessment_date: nil)
    new_assessment = new(
      data_source_id: user.data_source_id,
      user_id: user.user_id,
      personal_id: enrollment.personal_id,
      enrollment_id: enrollment.enrollment_id,
      assessment_date: assessment_date,
      data_collection_stage: Types::HmisSchema::Enums::AssessmentRole.as_data_collection_stage(form_definition.role),
    )
    new_assessment.custom_form = Hmis::Form::CustomForm.new(definition: form_definition)
    new_assessment
  end

  def self.hud_key
    nil
  end
end
