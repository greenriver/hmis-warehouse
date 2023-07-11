###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Household < Hmis::Hud::Base
  include ::Hmis::Concerns::HmisArelHelper

  self.table_name = :hmis_households
  self.primary_key = 'id'

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_many :enrollments, **hmis_relation(:HouseholdID, 'Enrollment')
  has_many :clients, through: :enrollments
  alias_attribute :household_id, :HouseholdID

  replace_scope :viewable_by, ->(user) do
    viewable_households = joins(:enrollments).
      merge(Hmis::Hud::Enrollment.viewable_by(user)). # does Data Source filter
      pluck(:HouseholdID)

    where(HouseholdID: viewable_households)
  end

  scope :client_matches_search_term, ->(text_search) do
    matching_ids = joins(:clients).
      merge(Hmis::Hud::Client.matching_search_term(text_search.to_s)).
      pluck(:id)

    where(id: matching_ids)
  end

  scope :open_on_date, ->(date) do
    where(hh_t[:earliest_entry].lteq(date)).
      where(hh_t[:latest_exit].eq(nil).or(hh_t[:latest_exit].gteq(date)))
  end

  # Households where ANY enrollment is open
  scope :active, -> do
    where(latest_exit: nil)
  end

  # Households where ALL enrollments are exited
  scope :exited, -> do
    where.not(latest_exit: nil)
  end

  # Households where ANY enrollment is WIP
  scope :in_progress, -> do
    where(any_wip: true)
  end

  # Households where NO enrollments are WIP
  scope :not_in_progress, -> do
    where(any_wip: false)
  end

  scope :with_project_type, ->(project_types) do
    joins(:project).merge(Hmis::Hud::Project.with_project_type(project_types))
  end

  def household_size
    enrollments.count
  end

  TRIMMED_HOUSEHOLD_ID_LENGTH = 6
  def self.short_id(hh_id)
    return hh_id unless hh_id.length == 32

    hh_id.first(TRIMMED_HOUSEHOLD_ID_LENGTH)
  end

  def short_id
    self.class.short_id(household_id)
  end

  SORT_OPTIONS = [
    :most_recent,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    most_recent: 'Most Recent',
  }.freeze

  def readonly?
    true
  end

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

  def self.apply_filters(input)
    Hmis::Filter::HouseholdFilter.new(input).filter_scope(self)
  end
end
