###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Household < Types::BaseObject
    include Types::HmisSchema::HasAssessments

    field :id, ID, null: false, method: :household_id
    field :short_id, ID, null: false
    field :household_clients, [HmisSchema::HouseholdClient], null: false
    field :household_size, Int, null: false
    field :annual_due_periods, [Types::DateRange], null: false

    assessments_field filter_args: { omit: [:project, :project_type], type_name: 'AssessmentsForHousehold' }

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
      enrollments.map(&:personal_id).uniq.size
    end

    def enrollments
      load_ar_association(object, :enrollments)
    end

    def assessments(**args)
      resolve_assessments(**args)
    end

    def annual_due_periods
      earliest_entry = object.earliest_entry
      household_exit_date = object.latest_exit
      max_year = household_exit_date&.year || Date.current.year

      ((earliest_entry.year + 1)..max_year).map do |year|
        due_period = Hmis::Reminders::ReminderGenerator.annual_due_period(earliest_entry_date: earliest_entry, year: year)
        # skip if household exited before the anniversary
        next if household_exit_date && household_exit_date < due_period.anniversary_date

        OpenStruct.new(start_date: due_period.due_period_start, end_date: due_period.due_period_end)
      end.compact
    end
  end
end
