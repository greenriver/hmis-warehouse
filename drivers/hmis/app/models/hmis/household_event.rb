# frozen_string_literal: true

#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
class Hmis::HouseholdEvent < Hmis::HmisBase
  JOIN = 'join'
  SPLIT = 'split'
  EVENT_TYPES = [JOIN, SPLIT].freeze # In the future we may add other events, like add and remove

  belongs_to :user, class_name: 'Hmis::User'
  belongs_to :household, class_name: 'Hmis::Hud::Household', primary_key: [:data_source_id, :HouseholdID], query_constraints: [:data_source_id, :HouseholdID], inverse_of: :events

  validates :event_type, inclusion: { in: EVENT_TYPES, message: '%{value} is not a valid event type' }

  alias_attribute :household_id, :HouseholdID

  def self.new_join_event(user:, household:, donor_household_id:, before_state:, after_state:)
    new(
      event_type: Hmis::HouseholdEvent::JOIN,
      user: user,
      household: household,
      event_details: {
        'donor_household_id': donor_household_id,
        'before': before_state,
        'after': after_state,
      },
    )
  end

  def self.new_split_event(user:, household:, receiving_household_id:, before_state:, after_state:)
    new(
      event_type: Hmis::HouseholdEvent::SPLIT,
      user: user,
      household: household,
      event_details: {
        'receiving_household_id': receiving_household_id,
        'before': before_state,
        'after': after_state,
      },
    )
  end
end
