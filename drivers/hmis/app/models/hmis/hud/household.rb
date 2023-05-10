###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Household < Hmis::Hud::Base
  self.table_name = :hmis_households
  self.primary_key = 'id'

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_many :enrollments, **hmis_relation(:HouseholdID, 'Enrollment')
  has_many :clients, through: :enrollments

  scope :client_matches_search_term, ->(text_search) do
    joins(:clients).merge(Hmis::Hud::Client.matching_search_term(text_search.to_s))
  end

  scope :viewable_by, ->(user) do
    joins(:enrollments).merge(Hmis::Hud::Enrollment.viewable_by(user))
  end

  scope :open_on_date, ->(date) do
    # TODO: AREL THIS!
    where('earliest_open <= ?', date).where('latest_exit is NULL or latest_exit >= ?', date)
  end

  scope :active, -> do
    where(latest_exit: nil)
  end

  scope :in_progress, -> do
    where(any_wip: true)
  end

  scope :not_in_progress, -> do
    where(any_wip: false)
  end

  def household_size
    enrollments.count
  end

  SORT_OPTIONS = [:most_recent].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      order(
        any_wip: :desc,
        earliest_open: :desc,
        DateCreated: :desc,
      )
    else
      raise NotImplementedError
    end
  end
end
