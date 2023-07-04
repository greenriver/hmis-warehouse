###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Household < Types::BaseObject
    description 'HUD Household'
    field :id, ID, null: false, method: :household_id
    field :short_id, ID, null: false
    field :household_clients, [HmisSchema::HouseholdClient], null: false
    field :household_size, Int, null: false

    # object is a Hmis::Hud::Household

    available_filter_options do
      arg :status, [HmisSchema::Enums::EnrollmentFilterOptionStatus]
      arg :open_on_date, GraphQL::Types::ISO8601Date
      arg :hoh_age_range, HmisSchema::Enums::AgeRange
      arg :search_term, String
    end

    def household_clients
      enrollments.map do |enrollment|
        {
          relationship_to_ho_h: enrollment.relationship_to_ho_h,
          enrollment: enrollment,
        }
      end
    end

    def household_size
      enrollments.size
    end

    def enrollments
      load_ar_association(object, :enrollments)
    end
  end
end
