###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::StaffAssignment < Hmis::HmisBase
  acts_as_paranoid

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :household, class_name: 'Hmis::Hud::Household', primary_key: [:data_source_id, :HouseholdID], foreign_key: [:data_source_id, :household_id], inverse_of: :staff_assignments
  belongs_to :staff_assignment_relationship, foreign_key: :hmis_staff_assignment_relationship_id, class_name: 'Hmis::StaffAssignmentRelationship'

  scope :viewable_by, ->(user) do
    # Special case this, rather than using EnrollmentRelated concern, because we have to join through Household
    joins_household_lateral.where(Hmis::Hud::Household.viewable_by_condition(user, lateral_household_t))
  end

  scope :open_on_date, ->(date = Date.current) do
    joins_household_lateral.where(Hmis::Hud::Household.open_on_date_condition(date, lateral_household_t))
  end

  scope :order_by_household_most_recent, -> do
    joins_household_lateral.order(*Hmis::Hud::Household.most_recent_order(lateral_household_t))
  end

  LATERAL_HOUSEHOLD_ALIAS = 'staff_assignment_households'

  # A plain join to the hmis_households view aggregates every enrollment before filtering. This LATERAL
  # aggregates only each assignment's household; OFFSET 0 keeps the planner from flattening it back.
  # Its own alias keeps it combinable with joins(:household).
  scope :joins_household_lateral, -> do
    joins(<<~SQL.squish)
      CROSS JOIN LATERAL (
        SELECT * FROM hmis_households hh
        WHERE hh."HouseholdID" = hmis_staff_assignments.household_id
          AND hh.data_source_id = hmis_staff_assignments.data_source_id
        OFFSET 0
      ) #{LATERAL_HOUSEHOLD_ALIAS}
    SQL
  end

  def self.lateral_household_t
    Hmis::Hud::Household.arel_table.alias(LATERAL_HOUSEHOLD_ALIAS)
  end
end
