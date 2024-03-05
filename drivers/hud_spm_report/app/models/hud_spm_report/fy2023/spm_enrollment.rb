###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class SpmEnrollment < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_enrollments'
    include ArelHelper
    include Detail

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :current_income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', optional: true
    belongs_to :previous_income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'

    has_many :enrollment_links
    has_many :episodes, through: :enrollment_links

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    scope :open_during_range, ->(range) do
      a_t = arel_table

      # SPM only runs on residential projects,
      # residential projects do not receive service on their exit date,
      # exclude exit date
      where(dates_overlaps_arel(range, a_t[:entry_date], a_t[:exit_date]), exit_date_included: false)
    end

    # HMIS Standard Reporting Terminology Glossary 2024 active client method 2
    #       (
    #         /* The exit date is in the date range, regardless of any service records attached to that enrollment. */
    #         [project exit date] >= [report start date] and [project exit date] <= [report end date]
    #       )
    #       or (
    #         /* The client entered before the end of the report range and has not yet exited,
    # or has exited in the future relative to the report range and there is a service in the report range. */
    #         [project start date] <= [report end date]
    #         and
    #           ( [project exit date] is null or [project exit date] > [report end date] )
    #         and
    #           [date of service] >= [report start date]
    #         and
    #           [date of service] <= [report end date]
    #         and
    #           [date of service] >= [project start date]
    scope :with_active_method_2_in_range, ->(range) do
      services_cond = GrdaWarehouse::Hud::Service.arel_table.then do |table|
        [
          table[:date_provided].between(range),
          table[:date_provided].gteq(arel_table[:entry_date]),
          # Bed nights cannot occur on the exit date, but CAN occur on the last day of the report
          # using, less than but pushing the end date out to include report end
          table[:date_provided].lt(cl(arel_table[:exit_date], range.last + 1.days)),
        ].inject(&:and)
      end

      cls_cond = GrdaWarehouse::Hud::CurrentLivingSituation.arel_table.then do |table|
        [
          table[:information_date].between(range),
          table[:information_date].gteq(arel_table[:entry_date]),
          # CLS can occur on exit date or report end
          table[:information_date].lteq(cl(arel_table[:exit_date], range.last)),
        ].inject(&:and)
      end

      # Projects using Method 2 must include Method 1 as a starting basis
      ee_cond = HudSpmReport::Fy2023::SpmEnrollment.arel_table.then do |table|
        [
          table[:project_type].not_in([1, 4]), # Not ES-NbN, or SO
          dates_overlaps_arel(range, table[:entry_date], table[:exit_date], exit_date_included: false),
        ].inject(&:and)
      end

      left_outer_joins(enrollment: [:services, :current_living_situations]).
        where(arel_table[:exit_date].between(range).or(services_cond.or(cls_cond).or(ee_cond)))
    end

    # HMIS Standard Reporting Terminology Glossary 2024 active client method 5
    scope :with_active_method_5_in_range, ->(range) do
      bed_night_cond = GrdaWarehouse::Hud::Service.arel_table.then do |table|
        [
          table[:record_type].eq(HudUtility2024.record_type('Bed Night', true)),
          table[:date_provided].between(range),
          table[:date_provided].gteq(arel_table[:entry_date]),
          # Bed nights cannot occur on the exit date, but CAN occur on the last day of the report
          # using, less than but pushing the end date out to include report end
          table[:date_provided].lt(cl(arel_table[:exit_date], range.last + 1.days)),
        ].inject(&:and)
      end

      nbn_cond = arel_table[:project_type].eq(1).and(bed_night_cond)

      ee_cond = HudSpmReport::Fy2023::SpmEnrollment.arel_table.then do |table|
        [
          table[:project_type].in([0, 2, 3, 8, 9, 10, 13]),
          dates_overlaps_arel(range, table[:entry_date], table[:exit_date], exit_date_included: false),
        ].inject(&:and)
      end

      left_outer_joins(enrollment: :services).where(nbn_cond.or(ee_cond))
    end

    scope :literally_homeless_at_entry_in_range, ->(range) do
      where(
        dates_overlaps_arel(range, arel_table[:entry_date], arel_table[:exit_date], exit_date_included: false).
        and(arel_table[:project_type].in([0, 1, 4, 8]).
          or(arel_table[:project_type].in([2, 3, 9, 10, 13]).
            and(arel_table[:prior_living_situation].between(100..199).
              or(arel_table[:previous_street_essh].eq(true).
                and(arel_table[:prior_living_situation].between(200..299)).
                and(arel_table[:los_under_threshold].eq(true))).
              or(arel_table[:previous_street_essh].eq(true).
                and(arel_table[:prior_living_situation].between(300..499)).
                and(arel_table[:los_under_threshold].eq(true)))))),
      )
    end

    HomelessnessInfo = Struct.new(:start_of_homelessness, :entry_date, :move_in_date, keyword_init: true)

    # Unlike, most HUD reports, there is not a single enrollment per report client, so the enrollment set
    # is constructed outside of the question universe, and then to preserve the 1:1 relationship between clients
    # and question universe members, the question universes either refer directly to an enrollment in this set, or
    # to an aggregation object that refers to enrollments in this set.
    def self.create_enrollment_set(report_instance)
      filter = ::Filters::HudFilterBase.new(user_id: report_instance.user.id).update(report_instance.options)
      enrollments = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter.new(report_instance).enrollments
      household_infos = household(enrollments)
      enrollments.preload(:client, :destination_client, :exit, :income_benefits_at_exit, :income_benefits_at_entry, :income_benefits, project: :funders).find_in_batches do |batch|
        members = []
        batch.each do |enrollment|
          current_income_benefits = current_income_benefits(enrollment, filter.end)
          previous_income_benefits = previous_income_benefits(enrollment, current_income_benefits&.information_date, filter.end)
          household_info = household_infos[enrollment.household_id] ||
            HomelessnessInfo.new(
              start_of_homelessness: enrollment.date_to_street_essh,
              entry_date: enrollment.entry_date,
              move_in_date: enrollment_own_move_in_date(enrollment),
            ) # If there is no HoH, use the enrollment
          members << {
            report_instance_id: report_instance.id,

            first_name: enrollment.client.first_name,
            last_name: enrollment.client.last_name,
            client_id: enrollment.destination_client.id,
            enrollment_id: enrollment.id,

            personal_id: enrollment.client.personal_id,
            data_source_id: enrollment.data_source_id,
            age: enrollment.client.age_on([filter.start, enrollment.entry_date].max),
            start_of_homelessness: start_of_homelessness(filter, household_info, enrollment),
            entry_date: enrollment.entry_date,
            exit_date: enrollment&.exit&.exit_date,
            move_in_date: move_in_date(household_info, enrollment),
            project_type: enrollment.project.project_type,
            eligible_funding: eligible_funding?(enrollment, filter.start, filter.end),
            destination: enrollment.exit&.destination,

            prior_living_situation: enrollment.living_situation,
            length_of_stay: enrollment.length_of_stay,
            los_under_threshold: enrollment.los_under_threshold == 1,
            previous_street_essh: enrollment.previous_street_essh == 1,

            current_income_benefits_id: current_income_benefits&.id,
            current_earned_income: earned_income(current_income_benefits),
            current_non_employment_income: non_employment_income(current_income_benefits),
            current_total_income: total_income(current_income_benefits),

            previous_income_benefits_id: previous_income_benefits&.id,
            previous_earned_income: earned_income(previous_income_benefits),
            previous_non_employment_income: non_employment_income(previous_income_benefits),
            previous_total_income: total_income(previous_income_benefits),

            days_enrolled: ([enrollment&.exit&.exit_date, filter.end].compact.min - enrollment.entry_date).to_i + 1, # enter and exit on the same day == 1 day
          }
        end
        import!(members)
      end
    end

    def self.detail_headers
      client_columns = ['client_id', 'first_name', 'last_name', 'personal_id', 'data_source_id']
      hidden_columns = ['id', 'report_instance_id', 'previous_income_benefits_id', 'current_income_benefits_id', 'enrollment_id'] + client_columns
      columns = client_columns + (column_names - hidden_columns)
      columns.map do |col|
        [col, header_label(col)]
      end.to_h
    end

    private_class_method def self.start_of_homelessness(filter, household_info, enrollment)
      age = enrollment.client.age_on([filter.start, enrollment.entry_date].max)
      start_of_homelessness = if age.present? && age <= 17 &&
        enrollment.entry_date == household_info.entry_date
        # Inherit start of homelessness from HoH for any household member aged <- 17 if they entered with the HoH
        household_info.start_of_homelessness
      else
        enrollment.date_to_street_essh
      end
      # Start of homelessness is never before birth
      start_of_homelessness = [start_of_homelessness, enrollment.client.dob].max if start_of_homelessness.present? && enrollment.client.dob.present?

      start_of_homelessness
    end

    private_class_method def self.move_in_date(household_info, enrollment)
      # Use the client move in date if they are the HoH
      return enrollment_own_move_in_date(enrollment) if enrollment.head_of_household?
      # Don't inherit move in date if the client exited before the HoH moved in
      return enrollment_own_move_in_date(enrollment) if enrollment.exit.present? && household_info.move_in_date.present? && enrollment.exit.exit_date <= household_info.move_in_date
      # Use the client's entry date if a client entered the household after the HoH had already moved in
      return enrollment.entry_date if household_info.move_in_date.present? && enrollment.entry_date > household_info.move_in_date

      # Otherwise, inherit move in date from HoH
      household_info.move_in_date
    end

    private_class_method def self.eligible_funding?(enrollment, start_date, end_date)
      enrollment.project.funders.any? do |funder|
        # Unroll open_between to allow preload
        funder.funder.in?(HudUtility2024.spm_coc_funders.map(&:to_s)) &&
          # Unroll open_between to allow preload
          (funder.end_date.nil? || funder.end_date >= start_date) &&
          funder.start_date <= end_date
      end
    end

    private_class_method def self.total_income(income_benefit)
      (income_benefit&.hud_total_monthly_income || 0).clamp(0..)
    end

    private_class_method def self.earned_income(income_benefit)
      (income_benefit&.earned_amount || 0).clamp(0..)
    end

    private_class_method def self.non_employment_income(income_benefit)
      (total_income(income_benefit) - earned_income(income_benefit)).clamp(0..)
    end

    private_class_method def self.current_income_benefits(enrollment, end_date)
      # Exit assessment for leavers, or most recent annual update within report range for stayers
      if enrollment.exit.present? && enrollment.exit.exit_date <= end_date
        enrollment.income_benefits_at_exit
      else
        # enrollment.
        #   income_benefits_annual_update.
        #   where(information_date: ..end_date).
        #   where(annual_update_window_sql(enrollment)).
        #   order(information_date: :desc).
        #   first
        enrollment.income_benefits.select do |ib|
          ib.data_collection_stage == 5 && ## Annual update
            ib.information_date <= end_date &&
            date_in_annual_update_window?(ib.information_date, enrollment)
        end.max_by(&:information_date)
      end
    end

    private_class_method def self.previous_income_benefits(enrollment, annual_date, end_date)
      return enrollment.income_benefits_at_entry if enrollment.exit.present? && enrollment.exit.exit_date <= end_date
      return enrollment.income_benefits_at_entry if annual_date.nil? # Return entry if no annual date

      # Most recent annual update on or before the renewal date, or the entry assessment
      # enrollment.
      #   income_benefits_annual_update.
      #   where(information_date: ...annual_date).
      #   where(annual_update_window_sql(enrollment)).
      #   order(information_date: :desc).
      #   first
      enrollment.income_benefits.select do |ib|
        ib.data_collection_stage == 5 && ## Annual update
          ib.information_date < annual_date &&
          date_in_annual_update_window?(ib.information_date, enrollment)
      end.max_by(&:information_date) || enrollment.income_benefits_at_entry # Default to entry assessment if less than 2 years
    end

    private_class_method def self.date_in_annual_update_window?(date, enrollment)
      entry_date = enrollment.entry_date
      interval = 30.days
      elapsed_years = date.year - entry_date.year
      window_date = entry_date + elapsed_years.years

      date.between?(window_date - interval, window_date + interval)
    end

    private_class_method def self.annual_update_window_sql(enrollment)
      # 30 days of anniversary of entry date
      report_date = ib_t[:information_date].to_sql
      entry_date = enrollment.entry_date.to_s(:db)
      interval = '30 days'
      <<~SQL
        (EXTRACT(MONTH FROM #{report_date}), EXTRACT(DAY FROM #{report_date})) IN (
          SELECT EXTRACT(MONTH FROM gs), EXTRACT(DAY FROM gs)
          FROM generate_series(
              '#{entry_date}'::date - INTERVAL '#{interval}',
              '#{entry_date}'::date + INTERVAL '#{interval}',
              '1 day'
          ) AS gs
        )
      SQL
    end

    private_class_method def self.enrollment_own_move_in_date(enrollment)
      return nil unless enrollment.move_in_date

      enrollment.move_in_date >= enrollment.entry_date ? enrollment.move_in_date : nil
    end

    private_class_method def self.household(enrollments)
      result = {}

      scope = enrollments.heads_of_households.order(e_t[:household_id], e_t[:move_in_date].asc.nulls_last)
      scope.find_in_batches do |batch|
        batch.each do |enrollment|
          result[enrollment.household_id] = HomelessnessInfo.new(
            start_of_homelessness: enrollment.date_to_street_essh,
            entry_date: enrollment.entry_date,
            move_in_date: enrollment_own_move_in_date(enrollment),
          )
        end
      end
      result
    end
  end
end
