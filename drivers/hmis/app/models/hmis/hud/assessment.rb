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

  SORT_OPTIONS = [:assessment_date].freeze
  WIP_ID = 'WIP'.freeze

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  has_one :assessment_detail, class_name: 'Hmis::Form::AssessmentDetail'
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :wip, class_name: 'Hmis::Wip', as: :source

  attr_accessor :in_progress

  validates_with Hmis::Hud::Validators::AssessmentValidator

  scope :in_progress, -> { where(enrollment_id: WIP_ID) }

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
      order(AssessmentDate: :desc)
    else
      raise NotImplementedError
    end
  end

  def save_in_progress
    saved_enrollment_id = enrollment.id

    self.enrollment_id = WIP_ID
    save!(validate: false)
    self.wip = Hmis::Wip.find_or_create_by(
      {
        source: self,
        enrollment_id: saved_enrollment_id,
        client_id: client.id,
        date: assessment_date,
      },
    )
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
end
