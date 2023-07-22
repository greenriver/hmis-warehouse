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
        results = enrollments.flat_map do |enrollment|
          [
            annual_assessment_reminder(enrollment),
            aged_into_adulthood_reminder(enrollment),
            intake_assessment_reminder(enrollment),
            exit_assessment_reminder(enrollment),
            current_living_situation_reminder(enrollment),
          ].compact
        end
        results.sort_by(&:sort_order)
      end

      protected

      def new_reminder(...)
        @sequence ||= 0
        @sequence +=1
        item = Hmis::Reminders::Reminder.new(...)
        item.id = @sequence.to_s
        item.overdue = today >= item.due_date
        item
      end

      def today
        @today ||= Date.current
      end

      def normalize_yoy_date(date)
        date.leap? && date.month == 2 && date.day == 29 ? date + 1.day : date
      end

      def data_stages(keys)
        @mapped ||= HudUtility.hud_list_map_as_enumerable(:data_collection_stage_map).symbolize_keys
        @mapped.fetch_values(*keys.map(&:to_sym))
      end

      def hoh_entry_date(enrollment)
        @hoh_anniversary_by_household_id ||= enrollments
          .group_by(&:household_id)
          .map do |household_id, group|
            hoh = group.detect { |e| e.RelationshipToHoH == 1 }
            [household_id, hoh&.EntryDate]
          end
          .to_h
        @hoh_anniversary_by_household_id[enrollment.household_id]
      end

      def last_assessment_date(enrollment:, stages:, wip:)
        # load all the assessments we might need
        @all_assessments ||= Hmis::Hud::CustomAssessment
          .where(EnrollmentID: enrollments.map(&:EnrollmentID), data_source_id: project.data_source_id)
          .order(AssessmentDate: :desc)
          .group_by(&:enrollment_id)

        assessments = @all_assessments[enrollment.EnrollmentID]
        return unless assessments

        stages = data_stages(stages)
        found = assessments.detect do |r|
          wip.include?(r.wip) && stages.include?(r.data_collection_stage)
        end
        found&.AssessmentDate
      end

      # Show reminder if ANY client in the household is missing an Annual Assessment within the
      # range when the annual is due, and today is on or after the start of that range.
      def annual_assessment_reminder(enrollment)
        hoh_entered_on = hoh_entry_date(enrollment)
        return unless hoh_entered_on

        hoh_entered_on = normalize_yoy_date(hoh_entered_on)
        window = 30.days
        # not due for an assessment yet
        return if today < (hoh_entered_on + (1.year - window))

        hoh_anniversary = hoh_entered_on.change(year: today.year)
        start_date = hoh_anniversary - window
        due_date = hoh_anniversary + window

        # a relevant assessment ocurred.
        # FIXME: maybe we don't include assessments that occur after end_date? This might
        # encourage people to back-date assessments.
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

        entry_date = enrollment.EntryDate
        adulthood_birthday = client.DOB + age_of_majority.years
        # the client was already an adult on entry date
        return if adulthood_birthday <= entry_date

        # client had an assessment after they became and adult
        last_assessed_on = last_assessment_date(enrollment: enrollment, stages: [:update, :annual_assessment], wip: [false])
        return if last_assessed_on && last_assessed_on >= adulthood_birthday

        new_reminder(
          topic: AGED_INTO_ADULTHOOD_TOPIC,
          due_date: normalize_yoy_date(adulthood_birthday),
          enrollment: enrollment,
        )
      end

      # Show reminder if: there are any household members that are missing intake assessments OR
      # have WIP intake assessments
      def intake_assessment_reminder(enrollment)
        # there's no submitted assessment
        return if last_assessment_date(enrollment: enrollment, stages: [:project_entry], wip: [false])

        new_reminder(
          topic: INTAKE_INCOMPLETE_TOPIC,
          due_date: enrollment.EntryDate,
          enrollment: enrollment,
        )
      end

      # Show reminder if: there are any WIP exit assessments for any household members
      def exit_assessment_reminder(enrollment)
        return unless last_assessment_date(enrollment: enrollment, stages: [:project_exit], wip: [true])

        new_reminder(
          topic: EXIT_INCOMPLETE_TOPIC,
          due_date: enrollment.EntryDate,
          enrollment: enrollment,
        )
      end

      # Show reminder if: there has not been a CurrentLivingSituation with an Information Date in the
      # past 90 days. Applies to Coordinated Entry projects only.
      def current_living_situation_reminder(enrollment)
        # ensure project is Coordinated Entry (14)
        cadence = project.ProjectType == 14 ? 90 : nil
        return unless cadence

        latest_living_situation_on = enrollment
          .current_living_situations
          .max_by(&:InformationDate)
          &.InformationDate

        due_date = latest_living_situation_on ? latest_living_situation_on + cadence : enrollment.EntryDate
        return if due_date > today

        new_reminder(
          topic: CURRENT_LIVING_SITUATION_TOPIC,
          due_date: due_date,
          enrollment: enrollment,
        )
      end

      # development cruft
      # def fake_reminders
      #   enrollment = enrollments.first
      #   due_date = today
      #   [
      #     new_reminder(
      #       topic: ANNUAL_ASSESSMENT_TOPIC,
      #       due_date: due_date,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: AGED_INTO_ADULTHOOD_TOPIC,
      #       due_date: due_date,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: INTAKE_INCOMPLETE_TOPIC,
      #       due_date: due_date,
      #       enrollment: enrollment,
      #     ),
      #     new_reminder(
      #       topic: EXIT_INCOMPLETE_TOPIC,
      #       due_date: due_date,
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
