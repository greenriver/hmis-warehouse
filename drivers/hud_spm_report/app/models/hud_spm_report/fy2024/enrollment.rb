###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2024
  class Enrollment < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_enrollments'
    include ArelHelper

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :current_income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', optional: true
    belongs_to :previous_income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'

    has_many :enrollment_links
    has_many :episodes, through: :enrollment_links

    # Unlike, most HUD reports, there is not a single enrollment per report client, so the enrollment set
    # is constructed outside of the question universe, and then to preserve the 1:1 relationship between clients
    # and question universe members, the question universes either refer directly to an enrollment in this set, or
    # to an aggregation object that refers to enrollments in this set.
    def self.create_enrollment_set(report_instance)
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(report_instance.options)
      household_infos = household(filter)
      enrollments(filter).find_in_batches do |batch|
        members = []
        batch.each do |enrollment|
          current_income_benefits = current_income_benefits(enrollment, filter.end)
          previous_income_benefits = previous_income_benefits(enrollment, current_income_benefits&.information_date)
          household_info = household_infos[enrollment.household_id] ||
            OpenStruct.new(
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
            previous_non_employment_income_: non_employment_income(previous_income_benefits),
            previous_total_income: total_income(previous_income_benefits),
          }
        end
        import!(members)
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
        funder.funder.in?([2, 3, 4, 5, 43, 44, 54, 55])
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

    private_class_method def self.enrollments(filter)
      HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter.new(filter).
        enrollments.
        preload(:client, :destination_client, :income_benefits, project: :funders)
    end

    private_class_method def self.household(filter)
      @household ||= {}.tap do |h|
        enrollments(filter).find_in_batches do |batch|
          batch.each do |enrollment|
            next unless enrollment.head_of_household?

            h[enrollment.household_id] = OpenStruct.new(
              start_of_homelessness: enrollment.date_to_street_essh,
              entry_date: enrollment.entry_date,
              move_in_date: enrollment.move_in_date,
            )
          end
        end
      end
    end
  end
end
