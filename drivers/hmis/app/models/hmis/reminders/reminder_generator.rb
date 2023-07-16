module Hmis
  module Reminders
    class ReminderGenerator

      # @param enrollments [Array<Hmis::Hud::Enrollment>]
      def perform(enrollments)
        # pull the whole collection down, we'll need it anyway
        enrollments.preload(:client, :project).to_a

        assessments = Hmis::Hud::CustomAssessment
          .where(enrollments: enrollments.map(:id))
          .where(data_collection_stage: [2, 5])
          .not_in_progress
          .order(AssessmentDate: :desc)
          .group(:enrollment_id)

        hoh_anniversary_by_household_id = enrollments
          .group_by(&:household_id)
          .map do |household_id, group|
            hoh_entry_date = group.detect {|e| RelationshipToHoH == 1 }*.EntryDate
            [household_id, hoh_entry_date]
          end.to_h

        enrollments.flat_map do |enrollment|
          [
            annual_assessment_reminder(
              enrollment: enrollment,
              hoh_entered_on: hoh_anniversary_by_household_id[enrollment.household_id],
              last_assessment_on: assessments.last_assessment_date(enrollment: enrollment, stages: [2])
            ),
            aged_into_adulthood_reminder(
              enrollment: enrollment,
              last_assessment_on: assessments.last_assessment_date(enrollment: enrollment, stages: [2, 5])
            ),
            # intake_incomplete_reminder(
            #   enrollment: enrollment,
            # ),
            # exit_incomplete_reminder(
            #   enrollment: enrollment,
            # ),
            # current_living_situation_reminder(
            #   enrollment: enrollment,
            # ),
          ].compact
        end
      end

      protected

      def last_assessment_date(enrollment: , stages: )
        found = assessments[enrollment.id]
        return unless found

        found.detect { |r| stages.includes?(r.data_collection_stage) }&.AssessmentDate
      end

      def today
        @today ||= Date.current
      end

      def normalize_yoy_date(date)
        (date.leap? && date.month == 2 && date.day == 29) ? date + 1.day : date
      end

      def annual_assessment_reminder(enrollment:, hoh_entered_on:, last_assessed_on: )
        hoh_entered_on = normalize_yoy_date(hoh_entered_on)
        window = 30.days
        # not due for an assessment yet
        return if today < (hoh_entered_on + (1.year - window))

        hoh_anniversary = hoh_entered_on.change(year: today.year)
        start_date = hoh_anniversary - window
        end_date = hoh_anniversary + window

        # a relevant assessment ocurred.
        # FIXME: maybe we don't include assessments that occur after end_date? This might
        # encourage people to back-date assessments.
        return if last_assessed_on && last_assessed_on >= start_date

        new_reminder(
          event_id: "annual_assessment",
          enrollment_id: enrollment_id,
          due_date: start_date,
          description: "#{enrollment.client.brief_name} needs an annual assessment",
        )
      end

      def aged_into_adulthood_reminder(enrollment, last_assessment_on: )
        client = enrollment.client
        return unless client.DOB

        entry_date = enrollment.EntryDate
        adulthood_birthday = client.DOB + 18.years
        # the client was already an adult on entry date
        return if adulthood_birthday >= entry_date

        # client had an assessment after they became and adult
        return if last_assessment_on >= adulthood_birthday

        new_reminder(
          event_id: "aged_into_adulthood",
          enrollment_id: enrollment_id,
          due_date: normalize_yoy_date(adulthood_birthday),
          description: "#{client.brief_name} has turned 18 and needs an assessment",
        )
      end

      def new_reminder(...)
        ReminderItem.new(...)
      end
    end
  end
end
