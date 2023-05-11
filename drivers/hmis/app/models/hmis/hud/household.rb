###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Household < Hmis::Hud::Base
  include ::Hmis::Concerns::HmisArelHelper
  include ::Hmis::Hud::Concerns::EnrollmentRelated

  self.table_name = :hmis_households
  self.primary_key = 'id'

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_many :enrollments, **hmis_relation(:HouseholdID, 'Enrollment')
  has_many :clients, through: :enrollments

  scope :client_matches_search_term, ->(text_search) do
    joins(:clients).merge(Hmis::Hud::Client.matching_search_term(text_search.to_s))
  end

  scope :open_on_date, ->(date) do
    # TODO: AREL THIS!
    where(hh_t[:earliest_entry].lteq(date)).where(hh_t[:latest_exit].eq(nil).or(hh_t[:latest_exit].gteq(date)))
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

  TRIMMED_HOUSEHOLD_ID_LENGTH = 6
  def short_id
    id.first(TRIMMED_HOUSEHOLD_ID_LENGTH)
  end

  SORT_OPTIONS = [:most_recent].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      order(
        hh_t[:any_wip].eq(true).desc,
        hh_t[:latest_exit].eq(nil).desc,
        earliest_entry: :desc,
      )
    else
      raise NotImplementedError
    end
  end
end
