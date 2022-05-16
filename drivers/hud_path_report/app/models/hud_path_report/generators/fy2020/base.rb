###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
module HudPathReport::Generators::Fy2020
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudPathReport::CommonQueries
    include HudReports::Incomes

    PATH_FUNDER_CODE = 21

    def initialize(generator = nil, report = nil, options: {})
      super
      options = report.options.with_indifferent_access.merge(user_id: report.user_id) if options.blank?
      @filter = HudPathReport::Filters::PathFilter.new(user_id: report.user_id).set_from_params(options)
    end

    private def universe
      add_clients unless clients_populated?
      @universe ||= @report.universe(self.class.question_number)
    end

    private def add_clients
      client_scope.find_in_batches(batch_size: 100) do |batch|
        pending_associations = {}
        batch.each do |client|
          enrollment = last_enrollment(client)
          next unless enrollment.present?

          source_client = enrollment.client
          next unless source_client

          max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.
            map(&:InformationDate).max
          disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

          max_health_and_dv_date = enrollment.health_and_dvs.select { |d| d.InformationDate <= @report.end_date }.
            map(&:InformationDate).max
          health_and_dv_latest = enrollment.health_and_dvs.detect { |d| d.InformationDate == max_health_and_dv_date }

          pending_associations[client] = report_client_universe.new(
            client_id: source_client.id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,
            first_name: source_client.FirstName,
            last_name: source_client.LastName,
            age: source_client.age_on([@report.start_date, enrollment.EntryDate].max),
            dob: source_client.DOB,
            dob_quality: source_client.DOBDataQuality,
            gender: source_client.Gender,
            am_ind_ak_native: source_client.AmIndAKNative,
            asian: source_client.Asian,
            black_af_american: source_client.BlackAfAmerican,
            native_hi_other_pacific: source_client.NativeHIOtherPacific,
            white: source_client.White,
            race_none: source_client.RaceNone,
            ethnicity: source_client.Ethnicity,
            veteran: source_client.VeteranStatus,
            substance_use_disorder: disabilities_latest.detect { |d| d.DisabilityType == 10 }&.DisabilityResponse,
            soar: last_income_in_period(enrollment.income_benefits)&.ConnectionWithSOAR,
            prior_living_situation: enrollment.LivingSituation,
            length_of_stay: enrollment.LengthOfStay,
            chronically_homeless: enrollment.chronically_homeless_at_start,
            domestic_violence: health_and_dv_latest&.DomesticViolenceVictim,
            active_client: active_in_path(enrollment),
            new_client: enrollment.EntryDate >= @report.start_date,
            enrolled_client: enrolled_in_path(enrollment),
            date_of_determination: enrollment.DateOfPATHStatus,
            reason_not_enrolled: enrollment.ReasonNotEnrolled,
            project_type: enrollment.project.ProjectType,
            first_date_in_program: enrollment.EntryDate,
            last_date_in_program: enrollment.exit&.ExitDate,
            contacts: path_contact_dates(enrollment),
            services: path_services(enrollment),
            referrals: path_referrals(enrollment),
            income_from_any_source_entry: enrollment.income_benefits_at_entry&.IncomeFromAnySource,
            incomes_at_entry: income_sources(enrollment.income_benefits_at_entry),
            income_from_any_source_exit: enrollment.income_benefits_at_exit&.IncomeFromAnySource,
            incomes_at_exit: income_sources(enrollment.income_benefits_at_exit),
            income_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.IncomeFromAnySource,
            incomes_at_report_end: income_sources(last_income_in_period(enrollment.income_benefits)),
            benefits_from_any_source_entry: enrollment.income_benefits_at_entry&.BenefitsFromAnySource,
            benefits_from_any_source_exit: enrollment.income_benefits_at_exit&.BenefitsFromAnySource,
            benefits_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.BenefitsFromAnySource,
            insurance_from_any_source_entry: enrollment.income_benefits_at_entry&.InsuranceFromAnySource,
            insurance_from_any_source_exit: enrollment.income_benefits_at_exit&.InsuranceFromAnySource,
            insurance_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.InsuranceFromAnySource,
            destination: enrollment.exit&.Destination,
          )
        end

        # Import clients
        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
            validate: false,
          },
        )

        # Attach clients to questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          universe_cell.add_universe_members(pending_associations)
        end
      end
    end

    private def clients_populated?
      @report.report_cells.joins(universe_members: :path_client).exists?
    end

    delegate :client_scope, to: :@generator

    private def last_enrollment(client)
      scope = client.source_enrollments.
        joins(project: :funders).
        open_during_range(@report.start_date..@report.end_date).
        merge(::GrdaWarehouse::Hud::Funder.funding_source(funder_code: PATH_FUNDER_CODE)). # PATH projects are PATH funded
        order(EntryDate: :desc)
      scope = scope.with_project_type(@filter.project_type_ids) if @filter.project_type_ids.present?
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope.first
    end

    private def last_income_in_period(income_benefits)
      income_benefits.
        where(ib_t[:InformationDate].lteq(@report.end_date)).
        order(InformationDate: :desc).
        first
    end

    private def active_in_path(enrollment)
      return true if enrollment.current_living_situations.between(start_date: @report.start_date, end_date: @report.end_date).exists?
      return true if enrollment.DateOfEngagement&.between?(@report.start_date, @report.end_date)
      return true if enrollment.ClientEnrolledInPATH == 1 && enrollment.DateOfPATHStatus&.between?(@report.start_date, @report.end_date)
      return true if enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).exists?

      false
    end

    private def enrolled_in_path(enrollment)
      return false unless enrollment.ClientEnrolledInPATH == 1
      return false unless enrollment.DateOfPATHStatus&.between?(enrollment.EntryDate, @report.end_date)

      enrollment.exit&.ExitDate.nil? || enrollment.DateOfPATHStatus <= enrollment.exit.ExitDate
    end

    private def path_contact_dates(enrollment)
      contacts = enrollment.current_living_situations.between(start_date: @report.start_date, end_date: @report.end_date).pluck(:InformationDate)
      contacts += [enrollment.DateOfEngagement] if enrollment.DateOfEngagement.present? && ! contacts.include?(enrollment.DateOfEngagement)
      contacts += [enrollment.DateOfPATHStatus] if enrollment.ClientEnrolledInPATH == 1 && ! contacts.include?(enrollment.DateOfPATHStatus)
      service_dates = enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).pluck(:DateProvided) - contacts
      contacts + service_dates
    end

    private def path_services(enrollment)
      enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).
        group(:DateProvided).pluck(:DateProvided, Arel.sql(array_agg(s_t[:TypeProvided]).to_sql)).to_h
    end

    private def path_referrals(enrollment)
      enrollment.services.path_referral.between(start_date: @report.start_date, end_date: @report.end_date).
        group(:DateProvided).pluck(:DateProvided, Arel.sql(array_agg(sql_array(s_t[:TypeProvided], s_t[:ReferralOutcome])).to_sql)).to_h
    end

    private def report_client_universe
      HudPathReport::Fy2020::PathClient
    end

    private def a_t
      report_client_universe.arel_table
    end
  end
end
