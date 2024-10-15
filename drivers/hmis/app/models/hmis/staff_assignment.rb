###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::StaffAssignment < Hmis::HmisBase
  acts_as_paranoid

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :household, class_name: 'Hmis::Hud::Household', primary_key: [:data_source_id, :HouseholdID], foreign_key: [:data_source_id, :household_id], inverse_of: :staff_assignments
  belongs_to :staff_assignment_relationship, foreign_key: :hmis_staff_assignment_relationship_id, class_name: 'Hmis::StaffAssignmentRelationship'

  scope :viewable_by, ->(user) do
    # Special case this, rather than using EnrollmentRelated concern, because we have to join through Household
    joins(:household).merge(Hmis::Hud::Household.viewable_by(user))
  end

  scope :open_on_date, ->(date = Date.current) do
    joins(:household).merge(Hmis::Hud::Household.open_on_date(date))
  end
end
