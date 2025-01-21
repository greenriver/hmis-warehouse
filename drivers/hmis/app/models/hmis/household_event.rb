#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
class Hmis::HouseholdEvent < Hmis::HmisBase
  JOIN = 'join'.freeze
  SPLIT = 'split'.freeze
  EVENT_TYPES = [JOIN, SPLIT].freeze # In the future we may add other events, like add and remove

  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :household, class_name: 'Hmis::Hud::Household', primary_key: [:data_source_id, :HouseholdID], foreign_key: [:data_source_id, :household_id], inverse_of: :events
  has_and_belongs_to_many :enrollments,
                          class_name: 'Hmis::Hud::Enrollment',
                          join_table: 'hmis_household_event_enrollments',
                          association_foreign_key: 'enrollment_id',
                          foreign_key: 'hmis_household_event_id'

  validates :event_type, inclusion: { in: EVENT_TYPES, message: '%{value} is not a valid event type' }
end
