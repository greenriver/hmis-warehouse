###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2024'
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
      HudUtility2024.path_project_type_codes
    end

    def initialize(report)
      super(report)
      return unless report&.persisted?

      Rails.logger.level = 1 if Rails.env.development?
      reset_report
      build_hopwa_caper_models
    end

    def reset_report
      report.hopwa_caper_enrollments.delete_all
      report.hopwa_caper_services.delete_all
      report.report_cells.with_deleted.destroy_all
      report.update! state: 'Waiting'
    end

    def url
      hud_reports_hopwa_caper_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HopwaCaper::Generators::Fy2024::Sheets::DemographicsAndPriorLivingSituationSheet,
        HopwaCaper::Generators::Fy2024::Sheets::TbraSheet,
        HopwaCaper::Generators::Fy2024::Sheets::StrmuSheet,
        HopwaCaper::Generators::Fy2024::Sheets::PhpSheet,
        HopwaCaper::Generators::Fy2024::Sheets::SupportiveServicesSheet,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      return question_number
    end

    def self.filter_class
      ::HopwaCaper::Filters::HopwaCaperFilter
    end

    def self.allowed_options
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
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date)
      # FIXME- I don't know how to create these from a spec
      return scope if Rails.env.test?

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      @filter.project_ids = @report.project_ids
      @filter.apply(scope)
    end

    def build_hopwa_caper_models
      scope = service_history_enrollments.preload(enrollment: [:income_benefits, :client, :disabilities, { project: :funders }])
      scope.in_batches(of: 100, order: :desc) do |batch|
        enrollment_rows = []
        service_rows = []
        batch.each do |service_history_enrollment|
          hud_enrollment = service_history_enrollment.enrollment

          enrollment_rows << HopwaCaper::Enrollment.from_hud_record(report: report, enrollment: hud_enrollment)
          service_rows += hud_enrollment.services.map do |hud_service|
            HopwaCaper::Service.from_hud_record(report: report, enrollment: hud_enrollment, service: hud_service)
          end
        end

        populate_hopwa_eligible(enrollment_rows)
        ensure_uniform_client_attrs(enrollment_rows)

        import_rows(HopwaCaper::Enrollment, enrollment_rows)
        import_rows(HopwaCaper::Service, service_rows)
      end
    end

    # ensure consistent values for individuals (can vary based on enrollment entry date)
    def ensure_uniform_client_attrs(enrollment_rows)
      groups = enrollment_rows.sort_by(&:id).group_by { |e| [e.data_source_id, e.hud_personal_id] }.values
      groups.each do |group|
        uniform_attrs = {
          age: group.map(&:age).compact.max,
          hiv_positive: groups.any?(:hiv_positive),
          ever_perscribed_anti_retroviral_therapy: groups.any?(:ever_perscribed_anti_retroviral_therapy),
          viral_load_supression: groups.any?(:viral_load_supression),
        }
        group.each { |e| e.attributes = uniform_attrs }
      end
    end

    # try and figure out which person in a household is hopwa eligible
    def populate_hopwa_eligible(enrollment_rows)
      households = enrollment_rows.sort_by(&:id).group_by { |e| [e.data_source_id, e.hud_household_id] }.values
      eligible_enrollments = households.map do |enrollments|
        # if the hoh is hiv+
        hohs = enrollments.filter { |e| e.relationship_to_hoh == 1 }
        next hohs.first if hohs.one? && hohs.first.hiv_positive

        # if there's only one hiv+ person in the household
        hiv = enrollments.filter(&:hiv_positive)
        next hiv.first if hiv.one?

        # first hiv+ person
        next hiv.first if hiv.any?

        # default to hoh
        hohs.first
      end
      eligible_enrollments.compact.each do |enrollment|
        enrollment.hopwa_eligible = true
      end
    end

    def import_rows(klass, rows)
      klass.import(rows, on_duplicate_key_ignore: true, validate: false)
    end
  end
end
