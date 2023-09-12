###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ChEnrollment < GrdaWarehouseBase
    include ArelHelper
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'

    scope :detached, -> do
      where.not(enrollment_id: GrdaWarehouse::Hud::Enrollment.select(:id))
    end

    scope :needs_processing, -> do
      joins(:enrollment).
        where(arel_table[:processed_as].not_eq(e_t[:processed_as]).or(arel_table[:processed_as].eq(nil))).
        or(where(enrollment_id: GrdaWarehouse::Hud::Enrollment.open_on_date.chronic.select(:id)))
    end

    scope :chronically_homeless, -> do
      where(chronically_homeless_at_entry: true)
    end

    def self.maintain!
      delete_missing!
      add_new!
      update_existing!
    end

    def self.delete_missing!
      ch_enrollment_ids = pluck(:enrollment_id)
      enrollment_ids = GrdaWarehouse::Hud::Enrollment.pluck(:id)
      missing = ch_enrollment_ids - enrollment_ids
      where(enrollment_id: missing).destroy_all if missing.any?
    end

    def self.add_new!
      ch_enrollment_ids = pluck(:enrollment_id)
      enrollment_ids = GrdaWarehouse::Hud::Enrollment.processed.pluck(:id)
      to_add = enrollment_ids - ch_enrollment_ids
      GrdaWarehouse::Hud::Enrollment.processed.
        preload(:project, :disabilities_at_entry).
        where(id: to_add).find_in_batches do |enrollments|
          batch = []
          enrollments.each do |enrollment|
            batch << {
              enrollment_id: enrollment.id,
              processed_as: enrollment.processed_as,
              chronically_homeless_at_entry: chronically_homeless_at_start?(enrollment, date: Date.current),
            }
          end
          import(batch)
        end
    end

    def self.update_existing!
      needs_processing.preload(enrollment: [:project, :disabilities_at_entry]).find_in_batches do |ch_enrollments|
        batch = []
        ch_enrollments.each do |ch_enrollment|
          enrollment = ch_enrollment.enrollment
          next unless enrollment.present?

          batch << {
            id: ch_enrollment.id, # Updates existing record
            enrollment_id: enrollment.id, # Not actually in the import, but required for well-formedness
            processed_as: enrollment.processed_as,
            chronically_homeless_at_entry: chronically_homeless_at_start?(enrollment, date: Date.current),
          }
        end
        import!(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:processed_as, :chronically_homeless_at_entry],
          },
        )
      end
    end

    # Accept an optional date which will be used for extending the homeless
    # range if the project is a homeless project
    def self.chronically_homeless_at_start?(enrollment, date: enrollment.EntryDate)
      chronically_homeless_at_start(enrollment, date: date) == :yes
    end

    # Was the client chronically homeless at the start of this enrollment?
    # Optionally accepts a date to use for "CH at a point-in-time" calculation.
    #
    # @return [Symbol] :yes, :no, :dk_or_r, or :missing
    def self.chronically_homeless_at_start(enrollment, date: enrollment.EntryDate)
      chronically_homeless_at_start_steps(enrollment, date: date).last[:result]
    end

    # Was the client chronically homeless at the start of this enrollment?
    # Optionally accepts a date to use for "CH at a point-in-time" calculation.
    #
    # @return [Array] all steps evaluated with result and display values.
    #
    # Each step in the array has this shape:
    # {
    #    result: Symbol [:yes, :no, :dk_or_r, :missing, :continue, :skip]
    #    display_value: value to display in chronic-at-entry explanation table
    #    line: [Number] line number in HUD calculation
    # }
    #
    # Result :continue means continue processing (and enter branch, if applicable)
    # Result :skip means continue processing but skip branch
    # Results :yes, :no, :dk_or_r, or :missing are the final CH status. Only the last step should have one of these as the result.
    def self.chronically_homeless_at_start_steps(enrollment, date: enrollment.EntryDate)
      steps = []
      # Line 1
      steps.push(disabling_condition(enrollment))
      return steps if terminating?(steps.last[:result])

      # Line 3
      steps.push(project_type(enrollment))
      if steps.last[:result] == :continue
        # Lines 4 - 6
        time_steps = homeless_duration_sufficient(enrollment, date: date)
        steps.push(*time_steps.each_with_index { |s, i| s[:line] = 4 + i })
        return steps if terminating?(steps.last[:result])
      end

      # Line 9
      steps.push(prior_living_sitation_homeless(enrollment))
      if steps.last[:result] == :continue
        # Lines 10 - 12
        time_steps = homeless_duration_sufficient(enrollment)
        steps.push(*time_steps.each_with_index { |s, i| s[:line] = 10 + i })
        return steps if terminating?(steps.last[:result])
      end

      # Line 14
      steps.push(prior_living_sitation_institutional(enrollment))
      if steps.last[:result] == :continue
        # Lines 15-16
        los_steps = length_of_stay_previous_sufficient(enrollment)
        steps.push(*los_steps.each_with_index { |s, i| s[:line] = 15 + i })
        return steps if terminating?(steps.last[:result])

        # Lines 17 - 19
        time_steps = homeless_duration_sufficient(enrollment)
        steps.push(*time_steps.each_with_index { |s, i| s[:line] = 17 + i })
        return steps if terminating?(steps.last[:result])
      end

      # Line 21
      steps.push(prior_living_sitation_other(enrollment))
      if steps.last[:result] == :continue
        # Lines 22-23
        los_steps = length_of_stay_previous_sufficient(enrollment)
        steps.push(*los_steps.each_with_index { |s, i| s[:line] = 22 + i })
        return steps if terminating?(steps.last[:result])

        # Lines 24 - 26
        time_steps = homeless_duration_sufficient(enrollment)
        steps.push(*time_steps.each_with_index { |s, i| s[:line] = 24 + i })
        return steps if terminating?(steps.last[:result])
      end

      # If we got this far, the client is not considered CH.
      # This also matches the last step (26) for clients who were homeless 4-11 months, since 'homeless_duration_sufficient' doesn't check for that.
      steps.last[:result] = :no
      steps
    end

    def self.dk_or_r_or_missing(value)
      return :dk_or_r if [8, 9].include?(value)
      return :missing if [nil, 99].include?(value)
    end

    def self.is_no?(value) # rubocop:disable Naming/PredicateName
      return :no if value&.zero?
    end

    def self.terminating?(sym)
      sym.in?([:yes, :no, :dk_or_r, :missing])
    end

    # Line 1 (3.08)
    def self.disabling_condition(enrollment)
      # if we don't have a yes from DisablingCondition, look to the disability entry records
      # if none of the disabilities are indefinite and impairing, then return the DisablingCondition
      result = if (is_no?(enrollment.DisablingCondition) || dk_or_r_or_missing(enrollment.DisablingCondition)) && enrollment.disabilities_at_entry&.map(&:indefinite_and_impairs?)&.none?(true)
        if is_no?(enrollment.DisablingCondition)
          :no
        else
          dk_or_r_or_missing(enrollment.DisablingCondition)
        end
      else
        :continue
      end

      { result: result, display_value: enrollment.DisablingCondition, line: 1 }
    end

    # Line 3 (2.02.6)
    def self.project_type(enrollment)
      ptype = enrollment.project.computed_project_type
      result = HudUtility2024.chronic_project_types.include?(ptype) ? :continue : :skip
      { result: result, display_value: "#{ptype} (#{::HudUtility2024.project_type_brief(ptype)})", line: 3 }
    end

    # Line 9  (3.917.1)
    def self.prior_living_sitation_homeless(enrollment)
      value = enrollment.LivingSituation
      result = HudUtility2024.homeless_situations(as: :prior).include?(value) ? :continue : :skip
      display_value = value ? "#{value} (#{::HudUtility2024.living_situation(value)})" : ''
      { result: result, display_value: display_value, line: 9 }
    end

    # Line 14 (3.917.1)
    def self.prior_living_sitation_institutional(enrollment)
      value = enrollment.LivingSituation
      result = HudUtility2024.institutional_situations(as: :prior).include?(value) ? :continue : :skip
      display_value = value ? "#{value} (#{::HudUtility2024.living_situation(value)})" : ''
      { result: result, display_value: display_value, line: 14 }
    end

    # Line 21 (3.917.1)
    def self.prior_living_sitation_other(enrollment)
      value = enrollment.LivingSituation
      is_other = (HudUtility2024.temporary_situations(as: :prior) + HudUtility2024.permanent_situations(as: :prior) + HudUtility2024.other_situations(as: :prior)).include?(value)
      display_value = value ? "#{value} (#{::HudUtility2024.living_situation(value)})" : ''
      { result: is_other ? :continue : :skip, display_value: display_value, line: 21 }
    end

    # Lines 4, 10, 17, and 24 (3.917.3)
    def self.approximate_start_date(enrollment, date: enrollment.EntryDate)
      ch_start_date = [enrollment.DateToStreetESSH, enrollment.EntryDate].compact.min
      project = enrollment.project
      days = if date != enrollment.EntryDate && (project.so? || project.es_nbn?)
        dates_in_enrollment_between(enrollment, enrollment.EntryDate, date).count + (enrollment.EntryDate - ch_start_date).to_i
      else
        (date - ch_start_date).to_i
      end
      result = days >= 365 ? :yes : :continue
      { result: result, display_value: "#{days} days  (#{ch_start_date.strftime('%m/%d/%Y')} - #{date.strftime('%m/%d/%Y')})" }
    end

    # Lines 5, 11, 18, and 25 (3.917.4)
    def self.num_times_homeless(enrollment)
      three_of_fewer_times_homeless = [1, 2, 3].freeze
      value = enrollment.TimesHomelessPastThreeYears

      result = if three_of_fewer_times_homeless.include?(value)
        :no
      elsif dk_or_r_or_missing(value)
        dk_or_r_or_missing(value)
      else
        :continue
      end

      { result: result, display_value: value }
    end

    # Lines 6, 12, 19, and 26 (3.917.4)
    def self.total_months_homeless(enrollment, date: enrollment.EntryDate)
      twelve_or_more_months_homeless = [112, 113].freeze # 112 = 12 months, 113 = 13+ months
      value = enrollment.MonthsHomelessPastThreeYears
      return { result: :yes, display_value: value - 100 } if twelve_or_more_months_homeless.include?(value)

      # If you don't have time prior to entry, day calculation above will catch any days during the enrollment
      # If you have time prior to entry and we are looking at an arbitrary date, we need to add
      # the months served. (This is only used for Chronic-at-PIT calculation, not Chronic-at-Entry).
      if date != enrollment.EntryDate && enrollment.MonthsHomelessPastThreeYears.present? && enrollment.MonthsHomelessPastThreeYears > 100
        project = enrollment.project
        months_in_enrollment = if project.so? || project.es_nbn?
          dates_in_enrollment_between(enrollment, enrollment.EntryDate, date).map do |d|
            [d.month, d.year]
          end.uniq.count
        else
          month_count = (date.year * 12 + date.month) - (enrollment.EntryDate.year * 12 + enrollment.EntryDate.month)
          # Subtract 1 from this number if the [project start date] does not fall on the first of the month.
          month_count -= 1 if month_count.positive? && enrollment.EntryDate.day != 1
          month_count
        end
        months_prior_to_enrollment = enrollment.MonthsHomelessPastThreeYears - 100
        sum = months_prior_to_enrollment + months_in_enrollment
        return { result: :yes, display_value: sum } if sum > 11
      end

      return { result: dk_or_r_or_missing(value), display_value: value } if dk_or_r_or_missing(value)

      { result: :continue, display_value: value - 100 }
    end

    def self.homeless_duration_sufficient(enrollment, date: enrollment.EntryDate)
      steps = [approximate_start_date(enrollment, date: date)]
      return steps if terminating?(steps.last[:result])

      steps.push(num_times_homeless(enrollment))
      return steps if terminating?(steps.last[:result])

      steps.push(total_months_homeless(enrollment, date: date))
      steps
    end

    # Add steps for lines 15-16 and lines 22-23
    def self.length_of_stay_previous_sufficient(enrollment)
      steps = []
      steps.push({ result: is_no?(enrollment.LOSUnderThreshold) || :continue, display_value: enrollment.LOSUnderThreshold })
      return steps if terminating?(steps.last[:result])

      steps.push({ result: is_no?(enrollment.PreviousStreetESSH) || :continue, display_value: enrollment.PreviousStreetESSH })
      steps
    end

    class << self
      include Memery
      def dates_in_enrollment_between(enrollment, start_date, end_date)
        enrollment.service_history_services.
          service_between(start_date: start_date, end_date: end_date).
          distinct.
          pluck(:date)
      end
      memoize :dates_in_enrollment_between
    end

    CH_AT_DATE_STEP_DESCRIPTIONS = {
      1 => {
        title: 'Disabling Condition',
        descriptions: ['If 1 (yes), CONTINUE processing using 3.917A (line 3) or B (line 8) as appropriate.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      3 => {
        title: 'Project Type',
        descriptions: ['If 0, 1, 4 or 8, CONTINUE processing on line 4.'],
      },
      4 => {
        title: 'Days since approximate start date',
        descriptions: ['If >= 365 days, CH = YES. STOP processing.', 'If missing or less than 365 days before [project start date], CONTINUE processing on line 5.'],
      },
      5 => {
        title: 'Number of times homeless',
        descriptions: ['If four or more times, CONTINUE processing on line 6.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      6 => {
        title: 'Total months homeless',
        descriptions: ['If >= 12, CH = YES. STOP processing.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      9 => {
        title: 'Prior Living Situation (3.917B Homeless Situation)',
        descriptions: ['If 100..199, CONTINUE processing on line 10.'],
      },
      10 => {
        title: 'Days since approximate start date',
        descriptions: ['If >= 365 days, CH = YES. STOP processing.', 'If missing or less than 365 days before [project start date], CONTINUE processing on line 11.'],
      },
      11 => {
        title: 'Number of times homeless',
        descriptions: ['If four or more times, CONTINUE processing on line 12.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      12 => {
        title: 'Total months homeless',
        descriptions: ['If >= 12, CH = YES. STOP processing.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      14 => {
        title: 'Prior Living Situation (3.917B Institutional Situation)',
        descriptions: ['If 200..299, CONTINUE processing on line 15.'],
      },
      15 => {
        title: 'Did you stay longer than 90 days?',
        descriptions: ['If 1 (yes), CONTINUE processing on line 16.', 'If 0 (no), CH = NO. STOP processing.'],
      },
      16 => {
        title: 'On the night before did you stay on the streets, ES or SH',
        descriptions: ['If 1 (yes), CONTINUE processing on line 17.', 'If 0 (no), CH = NO. STOP processing.'],
      },
      17 => {
        title: 'Days since approximate start date',
        descriptions: ['If >= 365 days, CH = YES. STOP processing.', 'If missing or less than 365 days before [project start date], CONTINUE processing on line 18.'],
      },
      18 => {
        title: 'Number of times homeless',
        descriptions: ['If four or more times, CONTINUE processing on line 19.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      19 => {
        title: 'Total months homeless',
        descriptions: ['If >= 12, CH = YES. STOP processing.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      21 => {
        title: 'Prior Living Situation (3.917B Temporary, Permanent, and Other Situations:)',
        descriptions: ['If  0..99 or in 300..499, CONTINUE processing on line 22.'],
      },
      22 => {
        title: 'Did you stay less than 7 nights?',
        descriptions: ['If 1 (yes), CONTINUE processing on line 23.', 'If 0 (no), CH = NO. STOP processing.'],
      },
      23 => {
        title: 'On the night before did you stay on the streets, ES or SH',
        descriptions: ['If 1 (yes), CONTINUE processing on line 24.', 'If 0 (no), CH = NO. STOP processing.'],
      },
      24 => {
        title: 'Days since approximate start date',
        descriptions: ['If >= 365 days, CH = YES. STOP processing.', 'If missing or less than 365 days before [project start date], CONTINUE processing on line 25.'],
      },
      25 => {
        title: 'Number of times homeless',
        descriptions: ['If four or more times, CONTINUE processing on line 26.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },
      26 => {
        title: 'Total months homeless',
        descriptions: ['If >= 12, CH = YES. STOP processing.', 'If 1 to 11 months, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
      },

    }.freeze

    # Here we map each executed result to the description information, using the line number
    def self.ch_at_entry_matrix(enrollment)
      chronically_homeless_at_start_steps(enrollment).map do |s|
        line_number = s[:line]
        step = CH_AT_DATE_STEP_DESCRIPTIONS[line_number]
        [line_number, step[:title], s[:display_value], s[:result], step[:descriptions]]
      end
    end
  end
end
