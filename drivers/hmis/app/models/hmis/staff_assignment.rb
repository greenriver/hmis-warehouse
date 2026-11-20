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
    joins_household_lateral.merge(Hmis::Hud::Household.viewable_by(user))
  end

  scope :open_on_date, ->(date = Date.current) do
    joins_household_lateral.merge(Hmis::Hud::Household.open_on_date(date))
  end

  # A plain join to the hmis_households view aggregates every enrollment before filtering. This LATERAL
  # aggregates only each assignment's household; OFFSET 0 keeps the planner from flattening it back.
  # Don't combine with joins(:household): both alias hmis_households.
  scope :joins_household_lateral, -> do
    joins(<<~SQL.squish)
      CROSS JOIN LATERAL (
        SELECT * FROM hmis_households hh
        WHERE hh."HouseholdID" = hmis_staff_assignments.household_id
          AND hh.data_source_id = hmis_staff_assignments.data_source_id
        OFFSET 0
      ) hmis_households
    SQL
  end
end
