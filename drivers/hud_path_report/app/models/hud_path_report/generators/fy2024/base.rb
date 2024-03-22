###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
module HudPathReport::Generators::Fy2024
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudPathReport::CommonQueries
    include HudReports::Incomes

    PATH_FUNDER_CODE = 21
    PRIOR_LIVING_SITUATION_ROWS = [
      ['Homeless Situations (100-199)', nil],
      [
        'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
        116,
      ],
      [
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, Host Home shelter',
        101,
      ],
      [
        'Safe Haven',
        118,
      ],
      ['Subtotal', :subtotal],
      ['Institutional Situations (200-299)', nil],
      [
        'Foster care home or foster care group home',
        215,
      ],
      [
        'Hospital or other residential non-psychiatric medical facility',
        206,
      ],
      [
        'Jail, prison, or juvenile detention facility',
        207,
      ],
      [
        'Long-term care facility or nursing home',
        225,
      ],
      # NOTE: the order of the next few situations are not consistent in Q25 and Q26
      [
        'Substance abuse treatment facility or detox center',
        205,
        'Q26',
      ],
      [
        'Psychiatric hospital or other psychiatric facility',
        204,
      ],
      [
        'Substance abuse treatment facility or detox center',
        205,
        'Q25',
      ],
      ['Subtotal', :subtotal],
      ['Temporary Housing Situations (300-399)', nil],
      [
        'Transitional housing for homeless persons (including homeless youth)',
        302,
      ],
      [
        'Residential project or halfway house with no homeless criteria',
        329,
      ],
      [
        'Hotel or motel paid for without emergency shelter voucher',
        314,
      ],
      [
        'Host Home (non-crisis)',
        332,
      ],
      [
        'Staying or living with family, temporary tenure (e.g., room, apartment, or house)',
        312, # ONLY Q25
      ],
      [
        'Staying or living with friends, temporary tenure (e.g., room, apartment, or house)',
        313, # ONLY Q25
      ],
      [
        'Moved from one HOPWA funded project to HOPWA TH',
        327, # ONLY Q25
      ],
      [
        'Staying or living in a friend’s room, apartment, or house',
        336, # ONLY Q26
      ],
      [
        'Staying or living in a family member’s room, apartment, or house',
        335, # ONLY Q26
      ],
      ['Subtotal', :subtotal],
      ['Permanent Housing Situations (400-499)', nil],
      [
        'Staying or living with family, permanent tenure',
        422,
      ],
      [
        'Staying or living with friends, permanent tenure',
        423,
      ],
      [
        'Moved from one HOPWA funded project to HOPWA PH',
        426,
      ],
      [
        'Rental by client, no ongoing housing subsidy',
        410,
      ],
      [
        'Rental by client, with ongoing housing subsidy',
        435,
      ],
      [
        'Owned by client, with ongoing housing subsidy',
        421,
      ],
      [
        'Owned by client, no ongoing housing subsidy',
        411,
      ],
      ['Subtotal', :subtotal],
      ['Other (1-99)', nil],
      [
        'No exit interview completed',
        30,
      ],
      [
        'Other',
        17,
      ],
      [
        'Deceased',
        24,
      ],
      [
        'Client doesn’t know',
        8,
      ],
      [
        'Client prefers not to answer',
        9,
      ],
      [
        'Data not collected',
        99,
      ],
      ['Subtotal', :subtotal],
      ['PATH-enrolled clients still active as of report end date (stayers)', :stayers],
      ['Total', :total],
    ].freeze

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
          enrollment = last_active_enrollment(client)
          next unless enrollment.present?

          source_client = enrollment.client
          next unless source_client

          max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.
            map(&:InformationDate).max
          disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

          max_health_and_dv_date = enrollment.health_and_dvs.select { |d| d.InformationDate <= @report.end_date }.
            map(&:InformationDate).max
          health_and_dv_latest = enrollment.health_and_dvs.detect { |d| d.InformationDate == max_health_and_dv_date }

          new_client = enrollment.EntryDate >= @report.start_date && no_earlier_active_enrollments?(client, enrollment)

          pending_associations[client] = report_client_universe.new(
            client_id: source_client.id,
            destination_client_id: client.id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,
            first_name: source_client.FirstName,
            last_name: source_client.LastName,
            personal_id: source_client.PersonalID,
            age: source_client.age_on([@report.start_date, enrollment.EntryDate].max),
            dob: source_client.DOB,
            dob_quality: source_client.DOBDataQuality,
            gender_multi: source_client.gender_multi.sort.join(','),
            race_multi: source_client.race_multi.sort.join(','),
            veteran: source_client.VeteranStatus,
            substance_use_disorder: disabilities_latest.detect { |d| d.DisabilityType == 10 }&.DisabilityResponse,
            soar: last_income_in_period(enrollment.income_benefits)&.ConnectionWithSOAR,
            prior_living_situation: enrollment.LivingSituation,
            length_of_stay: enrollment.LengthOfStay,
            chronically_homeless: enrollment.chronically_homeless_at_start,
            domestic_violence: health_and_dv_latest&.DomesticViolenceSurvivor,
            active_client: true, # Note, last_active_enrollment only returns active enrollments, so all are active, also, every question in the PATH report requires Active & ... so we really only report on active clients
            new_client: new_client,
            enrolled_client: enrolled_in_path(enrollment),
            newly_enrolled_client: newly_enrolled_in_path(enrollment),
            date_of_determination: enrollment.DateOfPATHStatus,
            reason_not_enrolled: enrollment.ReasonNotEnrolled,
            project_type: enrollment.project.ProjectType,
            first_date_in_program: enrollment.EntryDate,
            last_date_in_program: enrollment.exit&.ExitDate,
            contacts: path_contact_dates(client),
            services: path_services(enrollment),
            referrals: path_referrals(enrollment),
            cmh_service_provided: cmh_service_provided(enrollment),
            cmh_referral_provided_and_attained: cmh_referral_provided_and_attained(enrollment),
            income_from_any_source_entry: enrollment.income_benefits_at_entry&.IncomeFromAnySource || 99,
            incomes_at_entry: income_sources(enrollment.income_benefits_at_entry),
            income_from_any_source_exit: enrollment.income_benefits_at_exit&.IncomeFromAnySource || 99,
            incomes_at_exit: income_sources(enrollment.income_benefits_at_exit),
            income_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.IncomeFromAnySource || 99,
            incomes_at_report_end: income_sources(last_income_in_period(enrollment.income_benefits)),
            benefits_from_any_source_entry: enrollment.income_benefits_at_entry&.BenefitsFromAnySource || 99,
            benefits_from_any_source_exit: enrollment.income_benefits_at_exit&.BenefitsFromAnySource || 99,
            benefits_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.BenefitsFromAnySource || 99,
            insurance_from_any_source_entry: enrollment.income_benefits_at_entry&.InsuranceFromAnySource || 99,
            insurance_from_any_source_exit: enrollment.income_benefits_at_exit&.InsuranceFromAnySource || 99,
            insurance_from_any_source_report_end: last_income_in_period(enrollment.income_benefits)&.InsuranceFromAnySource || 99,
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

    private def enrollments(client)
      scope = client.source_enrollments.
        joins(project: :funders).
        open_during_range(@report.start_date..@report.end_date).
        merge(::GrdaWarehouse::Hud::Funder.funding_source(funder_code: PATH_FUNDER_CODE)). # PATH projects are PATH funded
        distinct. # sometimes projects have multiple funding sources all PATH, only include the project once
        order(EntryDate: :desc, DateUpdated: :desc)
      scope = scope.with_project_type(@filter.project_type_ids) if @filter.project_type_ids.present?
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    # Per HUD: Per discussions with SAMSHA and as discussed in the last vendor call, we're asking vendors to filter down to only the active enrollments first and then to keep only the most recent enrollment. This is intended to include clients in situations where, for instance, they were active for the first six months before being exited and then returned the day before the report end date and have no services yet.
    # So we will choose the most-recently started "active" enrollment
    private def last_active_enrollment(client)
      enrollments(client).detect do |en|
        active_in_path(en)
      end
    end

    # Part of the definition of New & Active is:
    # And (client does not have any enrollment identified as “active” as defined above with a [project start date] < [report start date])
    #
    # so we'll find any enrollments that overlap the reporting range that started before the report start
    # that aren't the "last" enrollment, and we'll look to see if any are active
    private def no_earlier_active_enrollments?(client, enrollment)
      enrollments(client).
        where(e_t[:EntryDate].lt(@report.start_date)).
        where.not(id: enrollment.id).
        map { |e| active_in_path(e) }.
        none?
    end

    private def last_income_in_period(income_benefits)
      income_benefits.
        where(ib_t[:InformationDate].lteq(@report.end_date)).
        order(InformationDate: :desc).
        first
    end

    private def active_in_path(enrollment)
      return true if enrollment.current_living_situations.between(start_date: @report.start_date, end_date: @report.end_date).exists?
      return true if enrollment.DateOfEngagement&.between?([@report.start_date, enrollment.EntryDate].max, [@report.end_date, enrollment.exit&.ExitDate].compact.min)
      return true if enrollment.ClientEnrolledInPATH == 1 && enrollment.DateOfPATHStatus&.between?([@report.start_date, enrollment.EntryDate].max, [@report.end_date, enrollment.exit&.ExitDate].compact.min)
      return true if enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).exists?
      return true if enrollment.real_exit_date&.between?(@report.start_date, @report.end_date)

      false
    end

    private def enrolled_in_path(enrollment)
      return false unless enrollment.ClientEnrolledInPATH == 1
      return false unless enrollment.DateOfPATHStatus.present?
      return false unless enrollment.DateOfPATHStatus <= @report.end_date
      return false unless enrollment.DateOfPATHStatus >= enrollment.EntryDate

      enrollment.exit&.ExitDate.nil? || enrollment.DateOfPATHStatus <= enrollment.exit.ExitDate
    end

    private def newly_enrolled_in_path(enrollment)
      return false unless enrollment.ClientEnrolledInPATH == 1
      return false unless enrollment.DateOfPATHStatus.present?
      return false unless enrollment.DateOfPATHStatus <= @report.end_date
      return false unless enrollment.DateOfPATHStatus >= @report.start_date
      return false unless enrollment.DateOfPATHStatus >= enrollment.EntryDate

      enrollment.exit&.ExitDate.nil? || enrollment.DateOfPATHStatus <= enrollment.exit.ExitDate
    end

    private def path_contact_dates(client)
      enrollment = last_active_enrollment(client)
      contacts = []

      min_date = [@report.start_date, enrollment.EntryDate].max
      max_date = [@report.end_date, enrollment.exit&.ExitDate].compact.min

      contacts += enrollment.current_living_situations.between(start_date: min_date, end_date: max_date).pluck(:InformationDate)
      contacts += [enrollment.DateOfEngagement] if enrollment.DateOfEngagement.present? && enrollment.DateOfEngagement.between?(min_date, max_date) && ! contacts.include?(enrollment.DateOfEngagement)
      contacts += [enrollment.DateOfPATHStatus] if enrollment.ClientEnrolledInPATH == 1 && enrollment.DateOfPATHStatus.between?(min_date, max_date) && ! contacts.include?(enrollment.DateOfPATHStatus)
      contacts += enrollment.services.path_service.between(start_date: min_date, end_date: max_date).pluck(:DateProvided).uniq.reject { |d| d.in?(contacts) }
      contacts
    end

    private def path_services(enrollment)
      enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).
        group(:DateProvided).pluck(:DateProvided, Arel.sql(array_agg(s_t[:TypeProvided]).to_sql)).to_h
    end

    private def cmh_service_provided(enrollment)
      enrollment.services.path_service.between(start_date: @report.start_date, end_date: @report.end_date).
        pluck(Arel.sql(s_t[:TypeProvided].to_sql)).include?(4)
    end

    private def path_referrals(enrollment)
      enrollment.services.path_referral.between(start_date: @report.start_date, end_date: @report.end_date).
        group(:DateProvided).pluck(:DateProvided, Arel.sql(array_agg(sql_array(s_t[:TypeProvided], s_t[:ReferralOutcome])).to_sql)).to_h
    end

    private def cmh_referral_provided_and_attained(enrollment)
      enrollment.services.path_referral.between(start_date: @report.start_date, end_date: @report.end_date).
        pluck(Arel.sql(sql_array(s_t[:TypeProvided], s_t[:ReferralOutcome]))).include?([1, 1])
    end

    private def report_client_universe
      HudPathReport::Fy2020::PathClient
    end

    private def a_t
      report_client_universe.arel_table
    end
  end
end
