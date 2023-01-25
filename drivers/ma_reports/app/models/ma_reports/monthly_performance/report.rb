###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include ArelHelper
    include Reporting::Status
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::LengthOfStays

    def run_and_save!
      start

      # Setup some household related data
      calculate_households
      create_universe

      # run!
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'Project Utilization by Month'
    end

    def self.report_options
      [
        :start,
        :end,
        :project_ids,
        :age_ranges,
        :household_type,
        :hoh_only,
        :sub_population,
        :coc_codes,
        :project_type_numbers,
        :age_ranges,
        :data_source_ids,
        :organization_ids,
        :project_ids,
        :funder_ids,
        :project_group_ids,
        :cohort_ids,
      ].freeze
    end

    def filter
      @filter ||= begin
        f = Filters::FilterBase.new(user_id: user_id, enforce_one_year_range: false)
        f.update(options)
      end
    end

    def url
      warehouse_reports_monthly_project_utilization_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      projects = {}
      enrollment_scope.find_in_batches(batch_size: 100) do |batch|
        enrollment_batch = {}

        batch.each do |enrollment|
          client = enrollment.client
          client_start_date = [filter.start_date, enrollment.first_date_in_program].max
          age = client.age_on(client_start_date)

          household_id = enrollment.enrollment.household_id || "#{enrollment.enrollment_group_id}*hh"
          cocs = enrollment.project.project_cocs || enrollment.project.build_project_coc
          cocs.each do |project_coc|
            new_enrollment = Enrollment.new(
              report: id,
              client: client.id,
              enrollment: enrollment.enrollment.id,
              project: enrollment.project.id,
              project_coc: project_coc,
              personal_id: client.personal_id,
              city: project.City,
              coc_code: project_coc.coc_code,
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
              latest_for_client: enrollment.id == @last_enrollment_ids[enrollment.client_id],
              chronically_homeless_at_entry: enrollment.enrollment&.ch_enrollment&.chronically_homeless_at_entry,
              stay_length_in_days: stay_length(enrollment),
              am_ind_ak_native: client.am_ind_ak_native == 1,
              asian: client.asian == 1,
              black_af_american: client.black_af_american == 1,
              native_hi_pacific: client.native_hi_pacific == 1,
              white: client.white == 1,
              ethnicity: client.ethnicity == 1,
              male: client.male == 1,
              female: client.female == 1,
              gender_other: client.gender_other == 1,
              transgender: client.trangender == 1,
              questioning: client.questioning == 1,
              no_single_gender: client.no_single_gender == 1,
              disabling_condition: enrollment.disabling_condition == 1,
              reporting_age: age,
              relationship_to_hoh: enrollment.enrollment.relationship_to_hoh,
              household_id: household_id,
              household_type: household_makeup(get_hh_id(enrollment), enrollment.first_date_in_program),
              household_members: households[get_hh_id(enrollment)],
              prior_living_situation: enrollment.enrollment.prior_living_situation,
              months_homeless_past_three_years: enrollment.enrollment.months_homeless_past_three_years,
              times_homeless_past_three_years: enrollment.enrollment.times_homeless_past_three_years,
            )
            projects[enrollment.project] ||= {} # TODO
            enrollment_batch[enrollment] = new_enrollment
          end
        end
        Enrollment.import(enrollment_batch.values)
        universe.add_universe_members(enrollment_batch)
      end
    end

    def enrollment_scope
      enrollment_scope_without_preloads.
        preload(:client, enrollment: [:exit, :ch_enrollment, project: [:project_cocs, :inventories]])
    end

    def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      filter.apply(scope)
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}
      @last_enrollment_ids ||= {}

      enrollment_scope.find_in_batches(batch_size: 100) do |batch|
        clients_with_enrollments(batch).each do |client_id, enrollments|
          @last_enrollment_ids[client_id] ||= enrollments.last.id
          enrollments.each do |enrollment|
            @hoh_enrollments[enrollment.client_id] = enrollment if enrollment.head_of_household?
            next unless enrollment&.enrollment&.client.present?

            date = [enrollment.first_date_in_program, @report.start_date].max
            age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
            @households[get_hh_id(enrollment)] ||= []
            @households[get_hh_id(enrollment)] << {
              client_id: enrollment.client_id,
              source_client_id: enrollment.enrollment.client.id,
              dob: enrollment.enrollment.client.DOB,
              age: age,
              veteran_status: enrollment.enrollment.client.VeteranStatus,
              chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
              chronic_detail: enrollment.enrollment.chronically_homeless_at_start,
              relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              # Include dates for determining if someone was present at assessment date
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
            }.with_indifferent_access
          end
        end
        GC.start
      end
    end

    # private def report_client_scope
    #   universe.members
    # end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:client_id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id).
        transform_values do |enrollments|
          enrollments.select do |enrollment|
            nbn_with_service?(enrollment)
          end
        end.
        reject { |_, enrollments| enrollments.empty? }
    end

    private def nbn_with_service?(enrollment)
      return true unless enrollment.nbn?

      @with_service ||= GrdaWarehouse::ServiceHistoryService.bed_night.
        service_excluding_extrapolated.
        service_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
        where(service_history_enrollment_id: enrollment_scope_without_preloads.select(:id)).
        pluck(:service_history_enrollment_id).to_set

      @with_service.include?(enrollment.id)
    end

    def report_end_date
      filter.end_date
    end
  end
end
