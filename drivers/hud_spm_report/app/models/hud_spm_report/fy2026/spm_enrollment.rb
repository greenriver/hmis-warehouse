###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2026
  class SpmEnrollment < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_enrollments'
    include ArelHelper
    include Detail

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :age

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
      ee_cond = HudSpmReport::Fy2026::SpmEnrollment.arel_table.then do |table|
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
          table[:record_type].eq(HudHelper.util('2026').record_type('Bed Night', true)),
          table[:date_provided].between(range),
          table[:date_provided].gteq(arel_table[:entry_date]),
          # Bed nights cannot occur on the exit date, but CAN occur on the last day of the report
          # using, less than but pushing the end date out to include report end
          table[:date_provided].lt(cl(arel_table[:exit_date], range.last + 1.days)),
        ].inject(&:and)
      end

      nbn_cond = arel_table[:project_type].eq(1).and(bed_night_cond)

      ee_cond = HudSpmReport::Fy2026::SpmEnrollment.arel_table.then do |table|
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

    def project_id
      enrollment&.project&.id
    end

    # Unlike, most HUD reports, there is not a single enrollment per report client, so the enrollment set
    # is constructed outside of the question universe, and then to preserve the 1:1 relationship between clients
    # and question universe members, the question universes either refer directly to an enrollment in this set, or
    # to an aggregation object that refers to enrollments in this set.
    def self.create_enrollment_set(report_instance)
      filter = ::Filters::HudFilterBase.new(user_id: report_instance.user.id).update(report_instance.options)
      enrollments = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter.new(report_instance).enrollments

      GrdaWarehouse::ServiceHistoryEnrollment.arel_table

      enrollments.preload(:client, :destination_client, :exit, :income_benefits_at_exit, :income_benefits_at_entry, :income_benefits, project: :funders).find_in_batches(batch_size: 500) do |batch|
        # Load contexts for THIS batch to minimize memory footprint
        # Identity is paired: [EnrollmentID, data_source_id]
        # Use raw SQL for composite IN clause as it's more reliable across different DB adapters
        pairs = batch.map { |e| [e.EnrollmentID, e.data_source_id] }
        placeholders = pairs.map { '(?, ?)' }.join(',')
        values = pairs.flatten

        she_mapping = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          where("(enrollment_group_id, data_source_id) IN (#{placeholders})", *values).
          pluck(:enrollment_group_id, :data_source_id, :id).
          each_with_object({}) do |(eg_id, ds_id, she_id), hash|
            hash[[eg_id, ds_id]] = she_id
          end

        contexts_by_she_id = HudReports::HouseholdContext.
          where(report_instance_id: report_instance.id, service_history_enrollment_id: she_mapping.values).
          index_by(&:service_history_enrollment_id)

        members = []

        batch.each do |enrollment|
          client = enrollment.client
          next if client.blank?

          # Find pre-computed context using paired identity
          she_id = she_mapping[[enrollment.EnrollmentID, enrollment.data_source_id]]
          context = contexts_by_she_id[she_id]
          next unless context # Skip if no context (shouldn't happen in normal flow)

          current_income_benefits = current_income_benefits(enrollment, filter.end)
          previous_income_benefits = previous_income_benefits(enrollment, current_income_benefits&.information_date, filter.end)

          attributes = SpmEnrollmentBuilder.build(
            report: report_instance,
            enrollment: enrollment,
            context: context,
            filter: filter,
            current_income: current_income_benefits,
            previous_income: previous_income_benefits,
          )

          members << attributes if attributes.present?
        end

        import!(members) if members.any?
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

    def self.pluck_project_ids
      project_table = GrdaWarehouse::Hud::Project.arel_table
      joins(enrollment: :project).distinct.pluck(project_table[:id])
    end

    def self.search_columns
      table = arel_table
      [
        table[:first_name],
        table[:last_name],
        table[:personal_id],
        Arel::Nodes::NamedFunction.new('CAST', [table[:client_id].as('TEXT')]),
      ]
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
      entry_date = enrollment.entry_date.to_fs(:db)
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
  end
end
