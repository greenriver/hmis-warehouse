###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Enrollment < Hmis::Hud::Base
  include ::HmisStructure::Enrollment
  include ::Hmis::Hud::Shared
  self.table_name = :Enrollment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  attr_accessor :in_progress

  delegate :exit_date, to: :exit, allow_nil: true

  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), optional: true
  has_one :exit, **hmis_relation(:EnrollmentID, 'Exit')
  has_many :services, **hmis_relation(:EnrollmentID, 'Service')
  has_many :events, **hmis_relation(:EnrollmentID, 'Event')
  has_many :assessments, **hmis_relation(:EnrollmentID, 'Assessment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  has_one :wip, class_name: 'Hmis::Wip', as: :source

  use_enum :relationships_to_hoh_enum_map, ::HUD.relationships_to_hoh

  after_save :maintain_wip

  SORT_OPTIONS = [:most_recent].freeze

  # A user can see any enrollment associated with a project they can access
  scope :viewable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
  end

  scope :heads_of_households, -> do
    where(RelationshipToHoH: 1)
  end

  scope :in_progress, -> { where(project_id: nil) }

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      order(EntryDate: :desc)
    else
      raise NotImplementedError
    end
  end

  def in_progress?
    @in_progress = project_id.nil? if @in_progress.nil?
    @in_progress
  end

  def maintain_wip
    if in_progress?
      Hmis::Wip.find_or_create_by(
        {
          enrollment_id: id,
          project_id: project_id,
          client_id: personal_id,
          date: entry_date,
          source: self,
        },
      )
    else
      return if wip.blank?

      update(project_id: wip.project_id)
      wip.destroy
    end
  end
end
