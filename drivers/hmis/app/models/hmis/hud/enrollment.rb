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

  delegate :exit_date, to: :exit, allow_nil: true

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_one :exit, **hmis_relation(:EnrollmentID, 'Exit')
  has_many :services, **hmis_relation(:EnrollmentID, 'Service')
  has_many :events, **hmis_relation(:EnrollmentID, 'Event')
  has_many :assessments, **hmis_relation(:EnrollmentID, 'Assessment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')

  SORT_OPTIONS = [:most_recent].freeze

  # A user can see any enrollment associated with a project they can access
  scope :viewable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
  end

  scope :heads_of_households, -> do
    where(RelationshipToHoH: 1)
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      order(EntryDate: :desc)
    else
      raise NotImplementedError
    end
  end
end
