###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This model is backed by a DB view
class Hmis::Hud::Household < Hmis::Hud::Base
  include ::Hmis::Concerns::HmisArelHelper

  self.table_name = :hmis_households
  self.primary_key = 'id'

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_many :enrollments, **hmis_relation(:HouseholdID, 'Enrollment')
  has_many :clients, through: :enrollments
  has_many :current_units, through: :enrollments
  has_many :custom_assessments, through: :enrollments
  alias_attribute :household_id, :HouseholdID

  replace_scope :viewable_by, ->(user) do
    # correlated subquery
    p_t = Hmis::Hud::Project.arel_table
    hh_t = Hmis::Hud::Household.arel_table
    cond = p_t[:ProjectID].eq(hh_t[:ProjectID]).and(p_t[:data_source_id].eq(hh_t[:data_source_id]))
    projects = Hmis::Hud::Project.with_access(user, :can_view_enrollment_details, :can_view_project, mode: 'all').where(cond)
    where(projects.arel.exists)
  end

  scope :client_matches_search_term, ->(text_search) do
    # FIXME: the sort order from text search is not preserved
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
    :hoh_last_name_a_to_z,
    :hoh_last_name_z_to_a,
    :hoh_first_name_a_to_z,
    :hoh_first_name_z_to_a,
    :hoh_age_youngest_to_oldest,
    :hoh_age_oldest_to_youngest,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    most_recent: 'Most Recent',
    hoh_last_name_a_to_z: 'Head of Household Last Name: A-Z',
    hoh_last_name_z_to_a: 'Head of Household Last Name: Z-A',
    hoh_first_name_a_to_z: 'Head of Household First Name: A-Z',
    hoh_first_name_z_to_a: 'Head of Household First Name: Z-A',
    hoh_age_youngest_to_oldest: 'Head of Household Age: Youngest to Oldest',
    hoh_age_oldest_to_youngest: 'Head of Household Age: Oldest to Youngest',
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
        id: :desc,
      )
    when :hoh_last_name_a_to_z
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:LastName].asc.nulls_last)
    when :hoh_last_name_z_to_a
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:LastName].desc.nulls_last)
    when :hoh_first_name_a_to_z
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:FirstName].asc.nulls_last)
    when :hoh_first_name_z_to_a
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:FirstName].desc.nulls_last)
    when :hoh_age_youngest_to_oldest
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:dob].desc.nulls_last)
    when :hoh_age_oldest_to_youngest
      joins(enrollments: :client).
        merge(Hmis::Hud::Enrollment.heads_of_households).
        order(c_t[:dob].asc.nulls_last)
    else
      raise NotImplementedError
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::HouseholdFilter.new(input).filter_scope(self)
  end
end
