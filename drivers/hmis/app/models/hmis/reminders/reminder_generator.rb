module Hmis
  module Reminders
    class ReminderGenerator
      attr_accessor :enrollments, :project

      def self.perform(...)
        new(...).perform
      end

      # @param project [Hmis::Hud::Project]
      # @param enrollments [ActiveRecord::Collection<Hmis::Hud::Enrollment>]
      def initialize(project:, enrollments:)
        self.project = project
        self.enrollments = enrollments.preload(:client, :current_living_situations).to_a
      end

      def perform
        enrollments.flat_map do |enrollment|
          [
            annual_assessment_reminder(enrollment),
            aged_into_adulthood_reminder(enrollment),
            intake_assessment_reminder(enrollment),
            exit_assessment_reminder(enrollment),
            current_living_situation_reminder(enrollment),
          ].compact
        end
      end

      protected

      def new_reminder(...)
        item = Hmis::Reminders::Reminder.new(...)
        item.overdue = item.due_date && today >= item.due_date
        item
      end

      def today
        @today ||= Date.current
      end

      def normalize_yoy_date(date)
        date.leap? && date.month == 2 && date.day == 29 ? date + 1.day : date
      end

      def data_stages(keys)
        @mapped ||= HudUtility2024.hud_list_map_as_enumerable(:data_collection_stages).symbolize_keys
        @mapped.fetch_values(*keys.map(&:to_sym))
      end

      def earliest_entry_date(enrollment)
        @earliest_entry_date_by_household_id ||= enrollments.
          group_by(&:household_id).
          map do |household_id, group|
            min_entry = group.map { |e| e.entry_date&.to_date }.compact.min
            [household_id, min_entry]
          end.
          to_h
        @earliest_entry_date_by_household_id[enrollment.household_id]
      end

      def last_assessment_date(enrollment:, stages:, wip:)
        # load all the assessments we might need
        @all_assessments ||= Hmis::Hud::CustomAssessment.
          where(enrollment_id: enrollments.map(&:enrollment_id), data_source_id: project.data_source_id).
          order(assessment_date: :desc).
          group_by(&:enrollment_id)

        assessments = @all_assessments[enrollment.enrollment_id]
        return unless assessments

        stages = data_stages(stages)
        found = assessments.detect do |r|
          wip.include?(r.wip) && stages.include?(r.data_collection_stage)
        end
        found&.assessment_date
      end

      # Show reminder if ANY client in the household is missing an Annual Assessment within the
      # range when the annual is due, and today is on or after the start of that range.
      def annual_assessment_reminder(enrollment)
        # Due date is based on the anniversary of the "first" HoH, which is the earliest
        # entry date across the whole household. This applies even if that person
        # has since exited the household.
        hoh_entered_on = earliest_entry_date(enrollment)
        return unless hoh_entered_on

        hoh_entered_on = normalize_yoy_date(hoh_entered_on)
        window = 30.days
        # not due for an assessment yet (household entered <11 months ago)
        return if today < (hoh_entered_on + (1.year - window))

        # Find the closest HOH entry anniversary
        hoh_anniversary = hoh_entered_on + ((today - hoh_entered_on) / Time.days_in_year).round.years

        # not due for an assessment yet (next due period is in the future)
        return if today < (hoh_anniversary - window)

        start_date = hoh_anniversary - window
        due_date = hoh_anniversary + window

        # client entered after the HoH anniversary
        return if enrollment.entry_date > hoh_anniversary

        # client exited before the HoH anniversary
        return if enrollment.exit_date && enrollment.exit_date < hoh_anniversary

        # a relevant assessment ocurred.
        # FIXME: maybe we don't include assessments that occur after end_date? This might
        # encourage people to back-date assessments.
        # TODO: should we check for presence in window? This wont show a task if the enrollment has a recent annual,
        # even if that annual falls outside of the "due period"  which is a data quality issue.
        last_assessed_on = last_assessment_date(enrollment: enrollment, stages: [:annual_assessment], wip: [false])
        return if last_assessed_on && last_assessed_on >= start_date

        new_reminder(
          topic: ANNUAL_ASSESSMENT_TOPIC,
          due_date: due_date,
          enrollment: enrollment,
        )
      end

      # Show reminder if a client in the household has turned 18 since the entry date, and they
      # have not had either an update or an annual since turning 18.
      def aged_into_adulthood_reminder(enrollment)
        age_of_majority = 18
        client = enrollment.client
        return unless client.DOB

        entry_date = enrollment.entry_date
        adulthood_birthday = normalize_yoy_date(client.DOB) + age_of_majority.years
        # the client was already an adult on entry date
        return if adulthood_birthday <= entry_date

        # client is still <18
        return if adulthood_birthday > today

        # client exited before turning 18
        return if enrollment.exit_date && enrollment.exit_date <= adulthood_birthday

        # client had an assessment after they became and adult
        last_assessed_on = last_assessment_date(enrollment: enrollment, stages: [:update, :annual_assessment], wip: [false])
        return if last_assessed_on && last_assessed_on >= adulthood_birthday

        new_reminder(
          topic: AGED_INTO_ADULTHOOD_TOPIC,
          due_date: adulthood_birthday,
          enrollment: enrollment,
        )
      end

      # Show reminder if: there are any household members that are missing intake assessments OR
      # have WIP intake assessments
      def intake_assessment_reminder(enrollment)
        # there is a submitted assessment
        return if last_assessment_date(enrollment: enrollment, stages: [:project_entry], wip: [false])

        new_reminder(
          topic: INTAKE_INCOMPLETE_TOPIC,
          due_date: enrollment.entry_date,
          enrollment: enrollment,
        )
      end

      # Show reminder if: there are any WIP exit assessments for any household members
      def exit_assessment_reminder(enrollment)
        return unless last_assessment_date(enrollment: enrollment, stages: [:project_exit], wip: [true])

        new_reminder(
          topic: EXIT_INCOMPLETE_TOPIC,
          enrollment: enrollment,
        )
      end

      # Show reminder if: there has not been a CurrentLivingSituation with an Information Date in the
      # past 90 days. Applies to Coordinated Entry projects only.
      def current_living_situation_reminder(enrollment)
        return if enrollment.exit_date.present?

        # CLS is only collected for HoH or Adults
        return unless enrollment.head_of_household? || enrollment.client.adult?

        # CLS is only "due" on a cadence for Coordinated Entry (14) (even though it can be collected for other project types)
        # FIXME: should we check funder applicability?
        cadence = project.ProjectType == 14 ? 90 : nil
        return unless cadence

        latest_living_situation_on = enrollment.
          current_living_situations.
          max_by(&:InformationDate)&.
          InformationDate

        due_date = latest_living_situation_on ? latest_living_situation_on + cadence : enrollment.entry_date
        return if due_date > today

        new_reminder(
          topic: CURRENT_LIVING_SITUATION_TOPIC,
          due_date: due_date,
          enrollment: enrollment,
        )
      end

      # development cruft
      # def fake_reminders(enrollment)
      #   due_date = today
      #   [
      #     new_reminder(
      #       topic: ANNUAL_ASSESSMENT_TOPIC,
      #       due_date: due_date + 1.month,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: AGED_INTO_ADULTHOOD_TOPIC,
      #       due_date: due_date - 2.months,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: INTAKE_INCOMPLETE_TOPIC,
      #       due_date: due_date - 1.month,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: EXIT_INCOMPLETE_TOPIC,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: CURRENT_LIVING_SITUATION_TOPIC,
      #       due_date: due_date,
      #       enrollment: enrollment,
      #     ),
      #   ]
      # end
    end
  end
end
