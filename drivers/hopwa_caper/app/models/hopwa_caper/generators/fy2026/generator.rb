# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# run manually with
# Reporting::Hud::RunReportJob.new.perform(HopwaCaper::Generators::Fy2026::Generator.name, HudReports::ReportInstance.last, email:false)
# @see docs/features/hopwa_caper.md
module HopwaCaper::Generators::Fy2026
  class Generator < ::HudReports::GeneratorBase
    SERVICE_LOOKBACK = 15.years

    def self.fiscal_year
      'FY 2026'
    end

    def self.generic_title
      'HOPWA CAPER'
    end

    def self.short_name
      'HOPWA CAPER'
    end

    def self.file_prefix
      "v1.0 #{short_name} #{fiscal_year}"
    end

    def self.default_project_type_codes
      # include ALL project types, we aren't sure which ones might be hopwa funded
      HudHelper.util('2026').project_type_group_titles.keys
    end

    def prepare_report(reset: Rails.env.development?)
      super()
      reset_report if reset
      build_hopwa_caper_models
    end

    def reset_report
      # Rails.logger.level = 1
      report.hopwa_caper_enrollments.delete_all
      report.hopwa_caper_services.delete_all
      report.report_cells.with_deleted.destroy_all
      # report.update! state: 'Waiting'
    end

    def url
      hud_reports_hopwa_caper_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HopwaCaper::Generators::Fy2026::Sheets::DemographicsAndPriorLivingSituationSheet,
        HopwaCaper::Generators::Fy2026::Sheets::TbraSheet,
        HopwaCaper::Generators::Fy2026::Sheets::StrmuSheet,
        HopwaCaper::Generators::Fy2026::Sheets::PhpSheet,
        HopwaCaper::Generators::Fy2026::Sheets::HousingInfoSheet,
        HopwaCaper::Generators::Fy2026::Sheets::SupportiveServicesSheet,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      return question_number
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.allowed_options(_)
      [
        :start,
        :end,
        :coc_codes,
        :project_ids,
        :data_source_ids,
        :project_type_codes,
        :project_group_ids,
      ]
    end

    protected

    def service_history_enrollments
      overlapping_enrollments = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date)

      # tbra has a 15 year look-back
      look_back = SERVICE_LOOKBACK
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report.start_date - look_back, end_date: @report.end_date).
        where(client_id: overlapping_enrollments.select(:client_id))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      @filter.project_ids = @report.project_ids
      @filter.apply(scope)
    end

    def build_hopwa_caper_models
      scope = service_history_enrollments.preload(enrollment: [:income_benefits, { client: :destination_client }, :disabilities, { project: :funders }, :services])
      scope.in_batches(of: 100, order: :desc) do |batch|
        enrollment_rows = []
        service_rows = []

        # Build a lookup hash to enable batched custom service queries.
        enrollment_context = {}

        batch.each do |service_history_enrollment|
          hud_enrollment = service_history_enrollment.enrollment

          client = hud_enrollment&.client&.destination_client
          next unless client

          enrollment_rows << HopwaCaper::Enrollment.from_hud_record(report: report, client: client, enrollment: hud_enrollment)

          # Store enrollment context for later custom service lookup
          context_key = [hud_enrollment.data_source_id, hud_enrollment.EnrollmentID]
          enrollment_context[context_key] = { enrollment: hud_enrollment, client: client }

          service_rows.concat(
            hud_enrollment.services.
              where(date_provided: service_date_range).
              map do |hud_service|
                HopwaCaper::Service.from_hud_service(
                  report: report,
                  client: client,
                  enrollment: hud_enrollment,
                  service: hud_service,
                )
              end,
          )
        end

        service_rows.concat(custom_service_rows_for(enrollment_context, date_range: service_date_range))

        import_rows(HopwaCaper::Enrollment, enrollment_rows)
        import_rows(HopwaCaper::Service, service_rows)
      end

      report.hopwa_caper_enrollments.distinct.pluck(:destination_client_id).in_groups_of(100, false) do |client_ids|
        enrollments = report.hopwa_caper_enrollments.where(destination_client_id: client_ids).order(:id)
        ensure_uniform_client_attrs(enrollments)
      end

      report.hopwa_caper_enrollments.distinct.pluck(:report_household_id).in_groups_of(100, false) do |household_ids|
        enrollments = report.hopwa_caper_enrollments.where(report_household_id: household_ids).order(:id)
        update_hopwa_eligibility(enrollments)
      end

      report.hopwa_caper_enrollments.distinct.pluck(:report_household_id).in_groups_of(100, false) do |household_ids|
        enrollments = report.hopwa_caper_enrollments.where(report_household_id: household_ids).order(:id)
        populate_household_aggregated_fields(enrollments)
      end

      true
    end

    # ensure consistent values for individuals (can vary based on enrollment entry date)
    def ensure_uniform_client_attrs(enrollment_rows)
      groups = enrollment_rows.sort_by(&:id).group_by(&:destination_client_id).values
      groups.each do |group|
        uniform_attrs = {
          age: group.map(&:age).compact.max,
          hiv_positive: group.any?(&:hiv_positive),
          ever_prescribed_anti_retroviral_therapy: group.any?(&:ever_prescribed_anti_retroviral_therapy),
          viral_load_suppression: group.any?(&:viral_load_suppression),
        }
        group.each do |enrollment|
          enrollment.attributes = uniform_attrs
          enrollment.save! if enrollment.changed?
        end
      end
    end

    # Determine which person in each household is HOPWA eligible.
    # HOPWA eligibility determination rules:
    # 1. If HoH is HIV+, they are eligible
    # 2. If only one person in household is HIV+, they are eligible
    # 3. Otherwise, first HIV+ person is eligible
    # 4. If no one is HIV+, HoH is eligible by default
    def update_hopwa_eligibility(enrollment_rows)
      households = enrollment_rows.group_by(&:report_household_id).values
      eligible_enrollments = households.filter_map { |enrollments| find_hopwa_eligible_enrollment(enrollments) }

      report.hopwa_caper_enrollments.
        where(id: eligible_enrollments.map(&:id)).
        update(hopwa_eligible: true)
    end

    def find_hopwa_eligible_enrollment(enrollments)
      hohs = enrollments.filter { |e| e.relationship_to_hoh == 1 }.sort_by(&:id)
      return hohs.first if hohs.one? && hohs.first.hiv_positive

      hiv = enrollments.filter(&:hiv_positive).sort_by(&:id)
      return hiv.first if hiv.one?
      return hiv.first if hiv.any?

      hohs.first
    end

    # Populate household-level income and insurance fields for all members.
    def populate_household_aggregated_fields(enrollments)
      rows_to_import = []

      enrollments.group_by(&:report_household_id).values.each do |household|
        income_sources = household.flat_map(&:income_benefit_source_types).uniq.sort
        insurance_types = household.flat_map(&:medical_insurance_types).uniq.sort

        household.each do |enrollment|
          enrollment.assign_attributes(
            household_income_benefit_source_types: income_sources,
            household_medical_insurance_types: insurance_types,
          )
          rows_to_import << enrollment
        end
      end

      return unless rows_to_import.any?

      HopwaCaper::Enrollment.import(
        rows_to_import,
        validate: false,
        on_duplicate_key_update: {
          conflict_target: [:report_instance_id, :enrollment_id],
          columns: [
            :household_income_benefit_source_types,
            :household_medical_insurance_types,
          ],
        },
      )
    end

    def import_rows(klass, rows)
      klass.import(rows, on_duplicate_key_ignore: true, validate: false)
    end

    private

    # Batch-fetch custom services for a set of enrollments to avoid N+1 queries.
    # Groups enrollments by data_source_id and issues one query per data source,
    # then uses the enrollment_context hash to link services back to their enrollments.
    def custom_service_rows_for(enrollment_context, date_range:)
      return [] if enrollment_context.empty?

      # Group by data_source_id to minimize queries (typically 1-2 per batch)
      grouped = enrollment_context.group_by { |(data_source_id, _enrollment_id), _| data_source_id }

      grouped.flat_map do |data_source_id, entries|
        enrollment_ids = entries.map { |(_data_source_key, enrollment_id), _| enrollment_id }

        # Fetch all custom services for this data source's enrollments in one query
        Hmis::Hud::CustomService.
          where(data_source_id: data_source_id, EnrollmentID: enrollment_ids).
          where(DateProvided: date_range).
          preload(custom_service_type: :custom_service_category).
          filter_map do |custom_service|
            # Use enrollment_context to retrieve the HUD enrollment and client
            key = [data_source_id, custom_service.EnrollmentID]
            context = enrollment_context[key]
            next unless context

            service_type = custom_service.custom_service_type
            next unless service_type

            service_category = service_type.custom_service_category
            next unless service_category

            HopwaCaper::Service.from_custom_service(
              report: report,
              enrollment: context.fetch(:enrollment),
              client: context.fetch(:client),
              service: custom_service,
            )
          end
      end
    end

    def service_date_range
      @service_date_range ||= (report.start_date - SERVICE_LOOKBACK)..report.end_date
    end
  end
end
