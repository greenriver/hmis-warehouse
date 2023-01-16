###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Enrollment < Hmis::Hud::Base
  include ::HmisStructure::Enrollment
  include ::Hmis::Hud::Concerns::Shared
  include ::HudConcerns::Enrollment
  include ArelHelper

  self.table_name = :Enrollment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  attr_accessor :in_progress

  delegate :exit_date, to: :exit, allow_nil: true

  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), optional: true
  has_one :exit, **hmis_relation(:EnrollmentID, 'Exit')
  has_many :services, **hmis_relation(:EnrollmentID, 'Service')
  has_many :events, **hmis_relation(:EnrollmentID, 'Event')
  has_many :income_benefits, **hmis_relation(:EnrollmentID, 'IncomeBenefit')
  has_many :disabilities, **hmis_relation(:EnrollmentID, 'Disability')
  has_many :health_and_dvs, **hmis_relation(:EnrollmentID, 'HealthAndDv')
  has_many :current_living_situations, **hmis_relation(:EnrollmentID, 'CurrentLivingSituation'), inverse_of: :enrollment
  has_many :enrollment_cocs, **hms_relation(:EnrollmentID, 'EnrollmentCoc')

  # NOTE: this does not include WIP assessments
  has_many :assessments, **hmis_relation(:EnrollmentID, 'Assessment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :enrollments
  has_one :wip, class_name: 'Hmis::Wip', as: :source

  SORT_OPTIONS = [:most_recent].freeze

  # hide previous declaration of :viewable_by, we'll use this one
  # A user can see any enrollment associated with a project they can access
  replace_scope :viewable_by, ->(user) do
    project_ids = Hmis::Hud::Project.viewable_by(user).pluck(:id, :ProjectID)
    viewable_wip = wip_t[:project_id].in(project_ids.map(&:first))
    viewable_enrollment = e_t[:ProjectID].in(project_ids.map(&:second))

    left_outer_joins(:wip).where(viewable_wip.or(viewable_enrollment))
  end

  # hide previous declaration of :editable_by, we'll use this one
  replace_scope :editable_by, ->(user) do
    project_ids = Hmis::Hud::Project.editable_by(user).pluck(:id, :ProjectID)
    editable_wip = wip_t[:project_id].in(project_ids.map(&:first))
    editable_enrollment = e_t[:ProjectID].in(project_ids.map(&:second))

    left_outer_joins(:wip).where(editable_wip.or(editable_enrollment))
  end

  def assessments_including_wip
    completed_assessments = as_t[:enrollment_id].eq(enrollment_id)
    wip_assessments = wip_t[:enrollment_id].eq(id)

    Hmis::Hud::Assessment.left_outer_joins(:wip).where(completed_assessments.or(wip_assessments))
  end

  scope :heads_of_households, -> do
    where(RelationshipToHoH: 1)
  end

  scope :in_progress, -> { where(project_id: nil) }

  def project
    super || Hmis::Hud::Project.find(wip.project_id)
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      left_outer_joins(:exit).order(
        e_t[:ProjectID].eq(nil).desc, # work-in-progress enrollments
        ex_t[:ExitDate].eq(nil).desc, # active enrollments
        EntryDate: :desc,
      )
    else
      raise NotImplementedError
    end
  end

  def self.generate_household_id
    generate_uuid
  end

  def self.generate_enrollment_id
    generate_uuid
  end

  def save_in_progress
    saved_project_id = project.id

    self.project_id = nil
    save!(validate: false)
    self.wip = Hmis::Wip.find_or_create_by(
      {
        source: self,
        project_id: saved_project_id,
        client_id: client.id,
        date: entry_date,
      },
    )
  end

  def save_not_in_progress
    transaction do
      self.project_id = project_id || project.project_id
      wip&.destroy
      save!
    end
  end

  def in_progress?
    @in_progress = project_id.nil? if @in_progress.nil?
    @in_progress
  end
end
