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

    def self.dk_or_r_or_missing(value)
      return :dk_or_r if [8, 9].include?(value)
      return :missing if [nil, 99].include?(value)
    end

    def self.is_no?(value) # rubocop:disable Naming/PredicateName
      return :no if value&.zero?
    end

    # TODO mini functions for each line
    # TODO function returning matrix for table

    # Accept an optional date which will be used for extending the homeless
    # range if the project is a homeless project
    def self.chronically_homeless_at_start?(enrollment, date: enrollment.EntryDate)
      chronically_homeless_at_start(enrollment, date: date) == :yes
    end

    # Was the client chronically homeless at the start of this enrollment?
    #
    # @return [Symbol] :yes, :no, :dk_or_r, or :missing
    def self.chronically_homeless_at_start(enrollment, date: enrollment.EntryDate)
      # Line 1
      return :no if is_no?(enrollment.DisablingCondition)
      return dk_or_r_or_missing(enrollment.DisablingCondition) if dk_or_r_or_missing(enrollment.DisablingCondition)

      # Line 3
      if GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(enrollment.project.computed_project_type)
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

    # TODO: test boundaries days/months for entry/exit, NbN, and SO
    def self.homeless_duration_sufficient(enrollment, date: enrollment.EntryDate)
      ch_start_date = [enrollment.DateToStreetESSH, enrollment.EntryDate].compact.min
      project = enrollment.project
      days = if date != enrollment.EntryDate && (project.so? || project.es? && project.bed_night_tracking?)
        dates_in_enrollment_between(enrollment.EntryDate, date).count + (enrollment.EntryDate - ch_start_date).to_i
      else
        (date - ch_start_date).to_i
      end
      return :yes if days > 365

      @three_or_fewer_times_homeless ||= [1, 2, 3].freeze
      return :no if @three_or_fewer_times_homeless.include?(enrollment.TimesHomelessPastThreeYears)
      return dk_or_r_or_missing(enrollment.TimesHomelessPastThreeYears) if dk_or_r_or_missing(enrollment.TimesHomelessPastThreeYears)

      @twelve_or_more_months_homeless ||= [112, 113].freeze # 112 = 12 months, 113 = 13+ months
      return :yes if @twelve_or_more_months_homeless.include?(enrollment.MonthsHomelessPastThreeYears)

      # If you don't have time prior to entry, day calculation above will catch any days during the enrollment
      # If you have time prior to entry and we are looking at an arbitrary date, we need to add
      # the months served
      if date != enrollment.EntryDate && enrollment.MonthsHomelessPastThreeYears.present? && enrollment.MonthsHomelessPastThreeYears > 100
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
        return :yes if (months_prior_to_enrollment + months_in_enrollment) > 11
      end

      return dk_or_r_or_missing(enrollment.MonthsHomelessPastThreeYears) if dk_or_r_or_missing(enrollment.MonthsHomelessPastThreeYears)
    end
  end
end
