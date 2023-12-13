###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class SpmEnrollment < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_enrollments'
    include ArelHelper

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

      d_1_start = range.first
      d_1_end = range.last
      d_2_start = a_t[:entry_date]
      d_2_end = a_t[:exit_date]

      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    # HMIS Standard Reporting Terminology Glossary 2024 active client method 2
    scope :with_active_method_2_in_range, ->(range) do
      services_cond = GrdaWarehouse::Hud::Service.arel_table.then do |table|
        [
          table[:record_type].eq(HudUtility2024.record_type('Bed Night', true)),
          table[:date_provided].between(range),
        ].inject(&:and)
      end

      ee_cond = HudSpmReport::Fy2023::SpmEnrollment.arel_table.then do |table|
        [
          table[:exit_date].gteq(range.begin),
          table[:entry_date].lteq(range.end),
        ].inject(&:and)
      end

      left_outer_joins(enrollment: :services).where(services_cond.or(ee_cond))
    end

    HomelessnessInfo = Struct.new(:start_of_homelessness, :entry_date, :move_in_date, keyword_init: true)

    # Unlike, most HUD reports, there is not a single enrollment per report client, so the enrollment set
    # is constructed outside of the question universe, and then to preserve the 1:1 relationship between clients
    # and question universe members, the question universes either refer directly to an enrollment in this set, or
    # to an aggregation object that refers to enrollments in this set.
    def self.create_enrollment_set(report_instance)
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(report_instance.options)
      enrollments = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter.new(filter).enrollments
      household_infos = household(enrollments)
      enrollments.preload(:client, :destination_client, :exit, :income_benefits, project: :funders).find_in_batches do |batch|
        puts "enrolment set batch #{Time.current.to_i}"
        members = []
        batch.each do |enrollment|
          current_income_benefits = current_income_benefits(enrollment, filter.end)
          previous_income_benefits = previous_income_benefits(enrollment, current_income_benefits&.information_date)
          household_info = household_infos[enrollment.household_id] ||
            HomelessnessInfo.new(
              start_of_homelessness: enrollment.date_to_street_essh,
              entry_date: enrollment.entry_date,
              move_in_date: enrollment.move_in_date,
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

            days_enrolled: ([enrollment&.exit&.exit_date, filter.end].compact.min - enrollment.entry_date).to_i,
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

    private_class_method def self.header_label(col)
      case col.to_sym
      when :client_id
        'Warehouse Client ID'
      when :personal_id
        'HMIS Personal ID'
      when :data_source_id
        'Data Source ID'
      when :los_under_threshold
        'LOS Under Threshold'
      when :previous_street_essh
        'Previous Street ESSH'
      else
        col.humanize
      end
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
      return enrollment.move_in_date if enrollment.head_of_household?
      # Don't inherit move in date if the client exited before the HoH moved in
      return enrollment.move_in_date if enrollment.exit.present? && household_info.move_in_date.present? && enrollment.exit.exit_date <= household_info.move_in_date
      # Use the client's entry date if a client entered the household after the HoH had already moved in
      return enrollment.entry_date if household_info.move_in_date.present? && enrollment.entry_date > household_info.move_in_date

      # Otherwise, inherit move in date from HoH
      household_info.move_in_date
    end

    private_class_method def self.eligible_funding?(enrollment, start_date, end_date)
      enrollment.project.funders.open_between(start_date: start_date, end_date: end_date).any? do |funder|
        funder.funder.in?([2, 3, 4, 5, 43, 44, 54, 55].map(&:to_s))
      end
    end

    private_class_method def self.total_income(income_benefit)
      (income_benefit&.total_monthly_income || 0).clamp(0..)
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
        enrollment.
          income_benefits_annual_update.
          where(information_date: ..end_date).
          where(annual_update_window_sql(enrollment)).
          order(information_date: :desc).
          first
      end
    end

    private_class_method def self.previous_income_benefits(enrollment, annual_date)
      # Most recent annual update on or before the renewal date, or the entry assessment
      enrollment.
        income_benefits_annual_update.
        where(information_date: ...annual_date).
        where(annual_update_window_sql(enrollment)).
        order(information_date: :desc).
        first || enrollment.income_benefits_at_entry # Default to entry assessment if less than 2 years
    end

    private_class_method def self.annual_update_window_sql(enrollment)
      update_window = (enrollment.entry_date - 30.days .. enrollment.entry_date + 30.days)

      "DATE_PART('month', #{ib_t[:information_date].to_sql}) >= #{update_window.first.month} AND " +
        "DATE_PART('day', #{ib_t[:information_date].to_sql}) >= #{update_window.first.day} AND " +
        "DATE_PART('month', #{ib_t[:information_date].to_sql}) <= #{update_window.last.month} AND " +
        "DATE_PART('day', #{ib_t[:information_date].to_sql}) <= #{update_window.last.day}"
    end

    private_class_method def self.household(enrollments)
      result = {}
      scope = enrollments.heads_of_households
      scope.find_in_batches do |batch|
        puts "household set batch #{Time.current.to_i}"
        batch.each do |enrollment|
          result[enrollment.household_id] = HomelessnessInfo.new(
            start_of_homelessness: enrollment.date_to_street_essh,
            entry_date: enrollment.entry_date,
            move_in_date: enrollment.move_in_date,
          )
        end
      end
      result
    end
  end
end
