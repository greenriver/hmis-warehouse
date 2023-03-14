###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Enrollment < Hmis::Hud::Base
  include ::HmisStructure::Enrollment
  include ::Hmis::Hud::Concerns::Shared
  include ::HudConcerns::Enrollment

  self.table_name = :Enrollment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  attr_accessor :in_progress

  delegate :exit_date, to: :exit, allow_nil: true

  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), optional: true
  has_one :exit, **hmis_relation(:EnrollmentID, 'Exit'), dependent: :destroy

  # HUD services
  has_many :services, **hmis_relation(:EnrollmentID, 'Service'), dependent: :destroy
  # Custom services
  has_many :custom_services, **hmis_relation(:EnrollmentID, 'CustomService'), dependent: :destroy
  # All services (combined view of HUD and Custom services)
  has_many :hmis_services, **hmis_relation(:EnrollmentID, 'HmisService')

  has_many :events, **hmis_relation(:EnrollmentID, 'Event'), dependent: :destroy
  has_many :income_benefits, **hmis_relation(:EnrollmentID, 'IncomeBenefit'), dependent: :destroy
  has_many :disabilities, **hmis_relation(:EnrollmentID, 'Disability'), dependent: :destroy
  has_many :health_and_dvs, **hmis_relation(:EnrollmentID, 'HealthAndDv'), dependent: :destroy
  has_many :current_living_situations, **hmis_relation(:EnrollmentID, 'CurrentLivingSituation'), inverse_of: :enrollment, dependent: :destroy
  has_many :enrollment_cocs, **hmis_relation(:EnrollmentID, 'EnrollmentCoc'), dependent: :destroy
  has_many :employment_educations, **hmis_relation(:EnrollmentID, 'EmploymentEducation'), dependent: :destroy
  has_many :youth_education_statuses, **hmis_relation(:EnrollmentID, 'YouthEducationStatus'), dependent: :destroy

  # CE Assessments
  has_many :assessments, **hmis_relation(:EnrollmentID, 'Assessment'), dependent: :destroy
  # Custom Assessments (note: this does NOT include WIP assessments)
  has_many :custom_assessments, **hmis_relation(:EnrollmentID, 'CustomAssessment'), dependent: :destroy

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :enrollments
  has_one :wip, class_name: 'Hmis::Wip', as: :source, dependent: :destroy

  SORT_OPTIONS = [:most_recent].freeze

  # hide previous declaration of :viewable_by, we'll use this one
  # A user can see any enrollment associated with a project they can access
  replace_scope :viewable_by, ->(user) do
    project_ids = Hmis::Hud::Project.viewable_by(user).pluck(:id, :ProjectID)
    viewable_wip = wip_t[:project_id].in(project_ids.map(&:first))
    viewable_enrollment = e_t[:ProjectID].in(project_ids.map(&:second))

    left_outer_joins(:wip).where(viewable_wip.or(viewable_enrollment))
  end

  scope :in_project_including_wip, ->(ids, project_ids) do
    wip_enrollments = wip_t[:project_id].in(Array.wrap(ids))
    actual_enrollments = e_t[:ProjectID].in(Array.wrap(project_ids))

    left_outer_joins(:wip).where(wip_enrollments.or(actual_enrollments))
  end

  def custom_assessments_including_wip
    completed_assessments = cas_t[:enrollment_id].eq(enrollment_id)
    wip_assessments = wip_t[:enrollment_id].eq(id)

    Hmis::Hud::CustomAssessment.left_outer_joins(:wip).where(completed_assessments.or(wip_assessments))
  end

  scope :heads_of_households, -> do
    where(RelationshipToHoH: 1)
  end

  scope :in_progress, -> { where(project_id: nil) }

  scope :not_in_progress, -> { where.not(project_id: nil) }

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

  def head_of_household?
    self.RelationshipToHoH == 1
  end

  def intake_assessment
    custom_assessments_including_wip.intakes.first
  end

  def exit_assessment
    custom_assessments_including_wip.exits.first
  end
end
