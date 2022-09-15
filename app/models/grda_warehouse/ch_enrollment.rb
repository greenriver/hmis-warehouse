###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      joins(:enrollment).where(arel_table[:processed_as].not_eq(e_t[:processed_as])).
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
        preload(:project).
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
      needs_processing.preload(enrollment: :project).find_in_batches do |ch_enrollments|
        batch = []
        ch_enrollments.each do |ch_enrollment|
          enrollment = ch_enrollment.enrollment
          batch << {
            id: ch_enrollment.id,
            processed_as: enrollment.processed_as,
            chronically_homeless_at_entry: chronically_homeless_at_start?(enrollment, date: Date.current),
          }
        end
        import(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:processed_as, :chronically_homeless_at_entry],
          },
        )
      end
    end

    # Line 1
    def self.disabling_condition(enrollment)
      result = if is_no?(enrollment.DisablingCondition)
        :no
      elsif dk_or_r_or_missing(enrollment.DisablingCondition)
        dk_or_r_or_missing(enrollment.DisablingCondition)
      end

      [result, enrollment.DisablingCondition]
    end

    # Line 3
    def self.project_type(enrollment)
      ptype = enrollment.project.computed_project_type
      result = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(ptype)
      [result, ::HUD.project_type_brief(ptype)]
    end

    def self.ch_at_entry_matrix(enrollment)
      steps = [
        {
          line: 1,
          title: 'Disabling Condition',
          descriptions: ['If 1 (yes), CONTINUE processing using 3.917A (line 3) or B (line 8) as appropriate.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
          method: :disabling_condition,
        },
        {
          line: 3,
          title: 'Project Type',
          descriptions: ['If 1, 4 or 8 (street outreach, shelter, or safe haven), CONTINUE processing on line 4.'],
          method: :project_type,
        },
        {
          line: 4,
          title: 'Days since approximate start date',
          descriptions: ['If > 365 days, CH = YES. STOP processing.', 'If missing or less than 365 days before [project start date], CONTINUE processing on line 5.'],
          method: :approximate_start_date,
        },
        {
          line: 5,
          title: 'Number of times homeless',
          descriptions: ['If four or more times, CONTINUE processing.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
          method: :num_times_homeless,
        },
        {
          line: 6,
          title: 'Total months homeless',
          descriptions: ['If >= 12, CH = YES. STOP processing.', 'If 1, 2, or 3 times, CH = NO. STOP processing.', 'If 8 or 9 then CH = DK/R. STOP processing', 'If 99 then CH = missing. STOP processing'],
          method: :total_months_homeless,
        },
      ]
      rows = []
      steps.each do |step|
        # some functions accept optional date, but we don't need it here because we're only using this for chronic-at-entry (not chronic-at-PIT)
        result, value = send(step[:method], enrollment)

        # sometimes result returns a boolean used by 'chronically_homeless_at_start' fn. ignore the value unless it is a final decision.
        result = nil unless result.in?([:yes, :no, :dk_or_r, :missing])
        rows.push([step[:line], step[:title], result, value, step[:descriptions]])

        # break if decision was reached
        # break if result
      end

      rows
    end

    # Was the client chronically homeless at the start of this enrollment?
    # Optionally accepts a date to use for "CH at a point-in-time" calculation.
    #
    # @return [Symbol] :yes, :no, :dk_or_r, or :missing
    def self.chronically_homeless_at_start(enrollment, date: enrollment.EntryDate)
      # Line 1
      result_1 = disabling_condition(enrollment)[0]
      return result_1 if result_1

      # Line 3
      result_3 = project_type(enrollment)[0]
      if result_3
        # Lines 4 - 6
        result = homeless_duration_sufficient(enrollment, date: date)
        return result if result
      end

      # Line 9
      if HUD.homeless_situations(as: :prior).include?(enrollment.LivingSituation)
        # Lines 10 - 12
        result = homeless_duration_sufficient(enrollment)
        return result if result
      end

      # Line 14
      if HUD.institutional_situations(as: :prior).include?(enrollment.LivingSituation)
        # Line 15
        return :no if is_no?(enrollment.LOSUnderThreshold)
        # Line 16
        return :no if is_no?(enrollment.PreviousStreetESSH)

        # Lines 17 - 19
        result = homeless_duration_sufficient(enrollment)
        return result if result
      end

      # Line 21
      if (HUD.temporary_and_permanent_housing_situations(as: :prior) + HUD.other_situations(as: :prior)).include?(enrollment.LivingSituation)
        # Line 22
        return :no if is_no?(enrollment.LOSUnderThreshold)
        # Line 23
        return :no if is_no?(enrollment.PreviousStreetESSH)

        # Lines 24 - 26
        result = homeless_duration_sufficient(enrollment)
        return result if result
      end

      return :no # Not included in flow -- added as fail safe
    end

    # Accept an optional date which will be used for extending the homeless
    # range if the project is a homeless project
    def self.chronically_homeless_at_start?(enrollment, date: enrollment.EntryDate)
      chronically_homeless_at_start(enrollment, date: date) == :yes
    end

    def self.dk_or_r_or_missing(value)
      return :dk_or_r if [8, 9].include?(value)
      return :missing if [nil, 99].include?(value)
    end

    def self.is_no?(value) # rubocop:disable Naming/PredicateName
      return :no if value&.zero?
    end

    # Lines 4, 10, 17, and 24
    # 3.917.3
    def self.approximate_start_date(enrollment, date: enrollment.EntryDate)
      ch_start_date = [enrollment.DateToStreetESSH, enrollment.EntryDate].compact.min
      project = enrollment.project
      days = if date != enrollment.EntryDate && (project.so? || project.es? && project.bed_night_tracking?)
        dates_in_enrollment_between(enrollment.EntryDate, date).count + (enrollment.EntryDate - ch_start_date).to_i
      else
        (date - ch_start_date).to_i
      end
      result = days > 365 ? :yes : nil
      [result, days]
    end

    # Lines 5, 11, 18, and 25 (3.917.4)
    def self.num_times_homeless(enrollment)
      @three_or_fewer_times_homeless ||= [1, 2, 3].freeze
      value = enrollment.TimesHomelessPastThreeYears

      return [:no, value] if @three_or_fewer_times_homeless.include?(value)

      return [dk_or_r_or_missing(value), value] if dk_or_r_or_missing(value)

      [nil, value]
    end

    # Lines 6, 12, 19, and 26 (3.917.4)
    def self.total_months_homeless(enrollment, date: enrollment.EntryDate)
      @twelve_or_more_months_homeless ||= [112, 113].freeze # 112 = 12 months, 113 = 13+ months
      value = enrollment.MonthsHomelessPastThreeYears
      return [:yes, value - 100] if @twelve_or_more_months_homeless.include?(value)

      # If you don't have time prior to entry, day calculation above will catch any days during the enrollment
      # If you have time prior to entry and we are looking at an arbitrary date, we need to add
      # the months served. (This is only used for Chronic-at-PIT calculation, not Chronic-at-Entry).
      if date != enrollment.EntryDate && enrollment.MonthsHomelessPastThreeYears.present? && enrollment.MonthsHomelessPastThreeYears > 100
        project = enrollment.project
        months_in_enrollment = if project.so? || project.es? && project.bed_night_tracking?
          dates_in_enrollment_between(enrollment.EntryDate, date).map do |d|
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
        return [:yes, sum] if sum > 11
      end

      return [dk_or_r_or_missing(value), value] if dk_or_r_or_missing(value)

      [nil, value - 100]
    end

    # TODO: test boundaries days/months for entry/exit, NbN, and SO
    def self.homeless_duration_sufficient(enrollment, date: enrollment.EntryDate)
      result = approximate_start_date(enrollment, date: date)[0]
      return result if result

      result = num_times_homeless(enrollment)[0]
      return result if result

      total_months_homeless(enrollment, date: date)[0]
    end
  end
end
