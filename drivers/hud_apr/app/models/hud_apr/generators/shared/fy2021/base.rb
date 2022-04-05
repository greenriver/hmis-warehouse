###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::Destinations
    include HudReports::Veterans
    include HudReports::LengthOfStays
    include HudReports::Incomes

    def self.filter_universe_members(associations)
      associations
    end
    # DEV NOTES: These can be run like so:
    # options = {user_id: 1, coc_code: 'KY-500', start_date: '2018-10-01', end_date: '2019-09-30', project_ids: [1797], generator_class: 'HudApr::Generators::Apr::Fy2021::Generator'}
    # HudApr::Generators::Shared::Fy2021::QuestionFour.new(options: options).run!

    # report = HudReports::ReportInstance.find(9)
    # generator = HudApr::Generators::Caper::Fy2021::Generator.new(report)
    # r = HudApr::Generators::Caper::Fy2021::QuestionFive.new(generator, report)

    private def universe
      add_apr_clients unless apr_clients_populated?

      @universe ||= @report.universe(self.class.question_number)
    end

    def needs_ce_assessments?
      false
    end

    private def add_apr_clients # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
      @generator.client_scope.find_in_batches(batch_size: 100) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)

        # Pre-calculate some values
        household_types = {}
        household_assessment_required = {}
        times_to_move_in = {}
        move_in_dates = {}
        approximate_move_in_dates = {}
        enrollments_by_client_id.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last

          hh_id = get_hh_id(last_service_history_enrollment)
          hoh_enrollment = enrollments_by_client_id[get_hoh_id(hh_id)]&.last
          household_assessment_required[hh_id] = annual_assessment_expected?(hoh_enrollment)
          end_date = if needs_ce_assessments?
            # Only HoHs get CE assessments, so we prefer their entry date
            hoh_enrollment&.first_date_in_program || last_service_history_enrollment.first_date_in_program
          else
            last_service_history_enrollment.first_date_in_program
          end
          date = [
            @report.start_date,
            end_date,
          ].max
          household_types[hh_id] = household_makeup(hh_id, date)
          times_to_move_in[last_service_history_enrollment.client_id] = time_to_move_in(last_service_history_enrollment)
          move_in_dates[last_service_history_enrollment.client_id] = appropriate_move_in_date(last_service_history_enrollment)
          approximate_move_in_dates[last_service_history_enrollment.client_id] = approximate_time_to_move_in(last_service_history_enrollment)
        end

        pending_associations = {}
        processed_source_clients = Set.new
        # Re-shape client to APR Client shape
        batch.each do |client|
          # Fetch enrollments for destination client
          enrollments = enrollments_by_client_id[client.id]
          next unless enrollments.present?

          last_service_history_enrollment = enrollments.last
          if needs_ce_assessments?
            hh_id = get_hh_id(last_service_history_enrollment)
            hoh_enrollment = enrollments_by_client_id[get_hoh_id(hh_id)]&.last
            ce_latest_assessment = latest_ce_assessment(last_service_history_enrollment, hoh_enrollment)
            ce_latest_event = latest_ce_event(last_service_history_enrollment, hoh_enrollment, ce_latest_assessment)
            #
            # Adjust last service history enrollment if falls outside assessment date
            if ce_latest_assessment.present?
              last_service_history_enrollment = enrollments.
                select do |e|
                  ce_latest_assessment.AssessmentDate.between?(
                    e.first_date_in_program,
                    e.last_date_in_program || @report.end_date,
                  )
                end.last
            end
          end
          next if last_service_history_enrollment.nil?

          enrollment = last_service_history_enrollment.enrollment
          source_client = enrollment.client
          next unless source_client

          client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

          exit_date = last_service_history_enrollment.last_date_in_program
          exit_record = last_service_history_enrollment.enrollment if exit_date.present? && exit_date <= @report.end_date

          income_at_start = enrollment.income_benefits_at_entry
          income_at_annual_assessment = annual_assessment(enrollment)
          income_at_exit = exit_record&.income_benefits_at_exit

          disabilities = enrollment.disabilities.select { |disability| [1, 2, 3].include?(disability.DisabilityResponse) }

          disabilities_at_entry = enrollment.disabilities.select { |d| d.DataCollectionStage == 1 }
          disabilities_at_exit = enrollment.disabilities.select { |d| d.DataCollectionStage == 3 }
          max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.
            map(&:InformationDate).max
          disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

          health_and_dv = enrollment.health_and_dvs.
            select { |h| h.InformationDate <= @report.end_date && !h.DomesticViolenceVictim.nil? }.
            max_by(&:InformationDate)

          last_bed_night = enrollment.services.select do |s|
            s.RecordType == 200 && s.DateProvided < @report.end_date
          end&.max_by(&:DateProvided)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(client_start_date)
          household_type = household_types[get_hh_id(last_service_history_enrollment)]
          # household_type = if age.blank? || age.negative?
          #   :unknown
          # else
          #   household_types[get_hh_id(last_service_history_enrollment)]
          # end
          annual_assessment_expected = household_assessment_required[get_hh_id(last_service_history_enrollment)]

          household_calculation_date = if needs_ce_assessments?
            ce_latest_assessment&.AssessmentDate || hoh_enrollment.first_date_in_program
          else
            last_service_history_enrollment.first_date_in_program
          end
          processed_source_clients << source_client.id
          ce_hash = {}
          options = {
            client_id: source_client.id,
            destination_client_id: last_service_history_enrollment.client_id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,

            age: age,
            alcohol_abuse_entry: [1, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_exit: [1, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_latest: [1, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
            annual_assessment_expected: annual_assessment_expected,
            annual_assessment_in_window: annual_assessment_in_window?(last_service_history_enrollment, income_at_annual_assessment&.InformationDate),
            approximate_time_to_move_in: approximate_move_in_dates[last_service_history_enrollment.client_id],
            came_from_street_last_night: enrollment.PreviousStreetESSH,
            chronic_disability_entry: disabilities_at_entry.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability_exit: disabilities_at_exit.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability_latest: disabilities_latest.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability: disabilities.detect(&:chronic?).present?,
            chronically_homeless: last_service_history_enrollment.enrollment.chronically_homeless_at_start?,
            chronically_homeless_detail: last_service_history_enrollment.enrollment.chronically_homeless_at_start,
            currently_fleeing: health_and_dv&.CurrentlyFleeing,
            date_homeless: enrollment.DateToStreetESSH,
            date_of_engagement: last_service_history_enrollment.enrollment.DateOfEngagement,
            date_of_last_bed_night: last_bed_night&.DateProvided,
            date_to_street: last_service_history_enrollment.enrollment.DateToStreetESSH,
            destination: last_service_history_enrollment.destination,
            developmental_disability_entry: disabilities_at_entry.detect(&:developmental?)&.DisabilityResponse,
            developmental_disability_exit: disabilities_at_exit.detect(&:developmental?)&.DisabilityResponse,
            developmental_disability_latest: disabilities_latest.detect(&:developmental?)&.DisabilityResponse,
            developmental_disability: disabilities.detect(&:developmental?).present?,
            disabling_condition: enrollment.DisablingCondition,
            dob_quality: source_client.DOBDataQuality,
            dob: source_client.DOB,
            domestic_violence: health_and_dv&.DomesticViolenceVictim,
            drug_abuse_entry: [2, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
            drug_abuse_exit: [2, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
            drug_abuse_latest: [2, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
            enrollment_coc: enrollment.enrollment_coc_at_entry&.CoCCode,
            enrollment_created: enrollment.DateCreated,
            ethnicity: source_client.Ethnicity,
            exit_created: exit_record&.exit&.DateCreated,
            first_date_in_program: last_service_history_enrollment.first_date_in_program,
            first_name: source_client.FirstName,
            gender_multi: source_client.gender_multi.sort.join(','),
            head_of_household_id: last_service_history_enrollment.head_of_household_id,
            head_of_household: last_service_history_enrollment[:head_of_household],
            hiv_aids_entry: disabilities_at_entry.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids_exit: disabilities_at_exit.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids_latest: disabilities_latest.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids: disabilities.detect(&:hiv?).present?,
            household_id: get_hh_id(last_service_history_enrollment),
            household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
            household_type: household_type,
            housing_assessment: last_service_history_enrollment.enrollment.exit&.HousingAssessment,
            income_date_at_annual_assessment: income_at_annual_assessment&.InformationDate,
            income_date_at_exit: income_at_exit&.InformationDate,
            income_date_at_start: income_at_start&.InformationDate,
            income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
            income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
            income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
            income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
            income_sources_at_exit: income_sources(income_at_exit),
            income_sources_at_start: income_sources(income_at_start),
            income_total_at_annual_assessment: income_at_annual_assessment&.hud_total_monthly_income,
            income_total_at_exit: income_at_exit&.hud_total_monthly_income,
            income_total_at_start: income_at_start&.hud_total_monthly_income,
            indefinite_and_impairs: disabilities.detect(&:indefinite_and_impairs?).present?,
            insurance_from_any_source_at_annual_assessment: income_at_annual_assessment&.InsuranceFromAnySource,
            insurance_from_any_source_at_exit: income_at_exit&.InsuranceFromAnySource,
            insurance_from_any_source_at_start: income_at_start&.InsuranceFromAnySource,
            last_date_in_program: last_service_history_enrollment.last_date_in_program,
            last_name: source_client.LastName,
            length_of_stay: stay_length(last_service_history_enrollment),
            bed_nights: bed_nights(last_service_history_enrollment),
            mental_health_problem_entry: disabilities_at_entry.detect(&:mental?)&.DisabilityResponse,
            mental_health_problem_exit: disabilities_at_exit.detect(&:mental?)&.DisabilityResponse,
            mental_health_problem_latest: disabilities_latest.detect(&:mental?)&.DisabilityResponse,
            mental_health_problem: disabilities.detect(&:mental?).present?,
            months_homeless: enrollment.MonthsHomelessPastThreeYears,
            move_in_date: last_service_history_enrollment.move_in_date,
            name_quality: source_client.NameDataQuality,
            non_cash_benefits_from_any_source_at_annual_assessment: income_at_annual_assessment&.BenefitsFromAnySource,
            non_cash_benefits_from_any_source_at_exit: income_at_exit&.BenefitsFromAnySource,
            non_cash_benefits_from_any_source_at_start: income_at_start&.BenefitsFromAnySource,
            # SHE other_clients_over_25 is computed at entry date, and we need to consider the report start date
            other_clients_over_25: ! only_youth?(
              OpenStruct.new(
                household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
                first_date_in_program: last_service_history_enrollment.first_date_in_program,
              ),
            ),
            overlapping_enrollments: overlapping_enrollments(enrollments, last_service_history_enrollment),
            # SHE parenting_youth is computed at entry date, and we need to consider the report start date
            parenting_youth: youth_parent?(
              OpenStruct.new(
                head_of_household: last_service_history_enrollment[:head_of_household],
                household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
                first_date_in_program: last_service_history_enrollment.first_date_in_program,
              ),
            ),
            pit_enrollments: pit_enrollment_info(enrollments),
            physical_disability_entry: disabilities_at_entry.detect(&:physical?)&.DisabilityResponse,
            physical_disability_exit: disabilities_at_exit.detect(&:physical?)&.DisabilityResponse,
            physical_disability_latest: disabilities_latest.detect(&:physical?)&.DisabilityResponse,
            physical_disability: disabilities.detect(&:physical?).present?,
            prior_length_of_stay: enrollment.LengthOfStay,
            prior_living_situation: enrollment.LivingSituation,
            project_tracking_method: last_service_history_enrollment.project_tracking_method,
            project_type: last_service_history_enrollment.computed_project_type,
            race: calculate_race(source_client),
            relationship_to_hoh: enrollment.RelationshipToHoH,
            ssn_quality: source_client.SSNDataQuality,
            ssn: source_client.SSN,
            subsidy_information: last_service_history_enrollment.enrollment.exit&.SubsidyInformation,
            substance_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse,
            substance_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse,
            substance_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse,
            substance_abuse: disabilities.detect(&:substance?).present?,
            time_to_move_in: times_to_move_in[last_service_history_enrollment.client_id],
            times_homeless: enrollment.TimesHomelessPastThreeYears,
            veteran_status: source_client.VeteranStatus,
          }
          if needs_ce_assessments?
            ce_hash = {
              household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
              other_clients_over_25: ! only_youth?(
                OpenStruct.new(
                  household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
                  first_date_in_program: last_service_history_enrollment.first_date_in_program,
                ),
              ),
              parenting_youth: youth_parent?(
                OpenStruct.new(
                  head_of_household: last_service_history_enrollment[:head_of_household],
                  household_members: household_member_data(last_service_history_enrollment, household_calculation_date),
                  first_date_in_program: last_service_history_enrollment.first_date_in_program,
                ),
              ),
              ce_assessment_date: ce_latest_assessment&.AssessmentDate,
              ce_assessment_type: ce_latest_assessment&.AssessmentType, # for Q9a
              ce_assessment_prioritization_status: ce_latest_assessment&.PrioritizationStatus, # for Q9b, Q9d
              ce_event_date: ce_latest_event&.EventDate,
              ce_event_event: ce_latest_event&.Event, # Q9c, Q9d
              ce_event_problem_sol_div_rr_result: ce_latest_event&.ProbSolDivRRResult,
              ce_event_referral_case_manage_after: ce_latest_event&.ReferralCaseManageAfter,
              ce_event_referral_result: ce_latest_event&.ReferralResult,
            }

          end

          pending_associations[client] = report_client_universe.new(options.merge(ce_hash))
        end

        # Import APR clients
        result = report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
          },
        )
        apr_clients = report_client_universe.where(id: result.ids)

        # Attach APR Clients to relevant questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          generator = @generator.class.questions[question_number]
          universe_cell.add_universe_members(generator.filter_universe_members(pending_associations))
        end

        # Add any associated data that needs to be linked back to the apr clients
        client_living_situations = []
        apr_clients.each do |apr_client|
          last_enrollment = enrollments_by_client_id[apr_client.destination_client_id].last.enrollment
          last_enrollment.current_living_situations.each do |living_situation|
            client_living_situations << apr_client.hud_report_apr_living_situations.build(
              information_date: living_situation.InformationDate,
              living_situation: living_situation.CurrentLivingSituation,
            )
          end
        end

        report_living_situation_universe.import(client_living_situations)

        if needs_ce_assessments?
          # Add any CE assessments and Events that occurred during the reporting period
          # regardless of enrollment
          assessments = []
          events = []
          apr_clients.each do |apr_client|
            last_enrollment = enrollments_by_client_id[apr_client.destination_client_id].last.enrollment
            last_enrollment.client.assessments.select do |assessment|
              assessment.AssessmentDate.present? &&
                assessment.AssessmentDate.between?(@report.start_date, @report.end_date) &&
                assessment.enrollment.project.id.in?(@report.project_ids)
            end.each do |assessment|
              assessments << apr_client.hud_report_ce_assessments.build(
                project_id: assessment.enrollment.project.id,
                assessment_date: assessment.AssessmentDate,
                assessment_level: assessment.AssessmentLevel,
              )
            end

            last_enrollment.client.events.select do |event|
              # NOTE: even though latest_ce_event may be 90 days after end of reporting period, Q10 is still fully limited by report range.
              event.EventDate.present? &&
                event.EventDate.between?(@report.start_date, @report.end_date) &&
                event.enrollment.project.id.in?(@report.project_ids)
            end.each do |event|
              events << apr_client.hud_report_ce_events.build(
                project_id: event.enrollment.project.id,
                event_date: event.EventDate,
                event: event.Event,
                problem_sol_div_rr_result: event.ProbSolDivRRResult,
                referral_case_manage_after: event.ReferralCaseManageAfter,
                referral_result: event.ReferralResult,
              )
            end
          end

          report_ce_assessment_universe.import(assessments)
          report_ce_event_universe.import(events)
        end
      end
    end

    private def apr_clients_populated?
      @report.report_cells.joins(universe_members: :apr_client).exists?
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id).
        transform_values { |enrollments| enrollments.reject { |enrollment| nbn_with_no_service?(enrollment) } }.
        reject { |_, enrollments| enrollments.empty? }
    end

    private def nbn_with_no_service?(enrollment)
      enrollment.project_tracking_method == 3 &&
        ! enrollment.service_history_services.
          bed_night.
          service_within_date_range(start_date: @report.start_date, end_date: @report.end_date).
          exists?
    end

    private def enrollment_scope
      preloads = {
        enrollment: [
          :disabilities,
          :current_living_situations,
          :project,
          :services,
          :income_benefits,
          :income_benefits_at_exit,
          :income_benefits_at_entry,
          :income_benefits_annual_update,
          :enrollment_coc_at_entry,
          :health_and_dvs,
          :exit,
          :assessments,
          client: [
            assessments: [
              enrollment: :project,
            ],
            events: [
              enrollment: :project,
            ],
          ],
        ],
      }
      enrollment_scope_without_preloads.preload(preloads)
    end

    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(:enrollment)
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    private def pit_enrollment_info(enrollments)
      pit_dates = [1, 4, 7, 10].map { |month| pit_date(month: month, before: @report.end_date) }
      pit_dates.map do |pit_date|
        enrollments_for_date = enrollments.select do |enrollment|
          enrolled = case enrollment.computed_project_type
          when 3, 13 # PSH/RRH
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program > pit_date) && # Exclude exit date
              enrollment.move_in_date.present? && # Check that move in date is present and is before the PIT data
              enrollment.move_in_date <= pit_date
          when 1, 2, 8, 9, 10 # Other residential
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program > pit_date) # Exclude exit date
          else # Other project types (4, 6, 11)
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program >= pit_date) # Include the exit date
          end
          next false unless enrolled
          next true if enrollment.computed_project_type != 1 || enrollment.project_tracking_method != 3 # Not ES or ES and not NbN

          enrollment.service_history_services.bed_night.on_date(pit_date).exists?
        end.map do |enrollment|
          {
            first_date_in_program: enrollment.first_date_in_program,
            last_date_in_program: enrollment.last_date_in_program,
            project_type: enrollment.project_type,
            project_tracking_method: enrollment.project_tracking_method,
            move_in_date: enrollment.move_in_date,
          }
        end
        [pit_date, enrollments_for_date]
      end.to_h.select { |_, v| v.present? }
    end

    delegate :client_scope, to: :@generator
    delegate :end_date, to: :@report, prefix: :report

    private def report_client_universe
      HudApr::Fy2020::AprClient
    end

    private def report_living_situation_universe
      HudApr::Fy2020::AprLivingSituation
    end

    private def report_ce_assessment_universe
      HudApr::Fy2020::CeAssessment
    end

    private def report_ce_event_universe
      HudApr::Fy2020::CeEvent
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def ethnicities
      {
        '0' => {
          order: 1,
          label: 'Non-Hispanic/Non-Latin(a)(o)(x)',
          clause: a_t[:ethnicity].eq(0),
        },
        '1' => {
          order: 2,
          label: 'Hispanic/Latin(a)(o)(x)',
          clause: a_t[:ethnicity].eq(1),
        },
        '8 or 9' => {
          order: 3,
          label: 'Client Doesn’t Know/Client Refused',
          clause: a_t[:ethnicity].in([8, 9]),
        },
        '99' => {
          order: 4,
          label: 'Data Not Collected',
          clause: a_t[:ethnicity].eq(99).or(a_t[:ethnicity].eq(nil)),
        },
        'Total' => {
          order: 5,
          label: 'Total',
          clause: Arel.sql('1=1'),
        },
      }.sort_by { |_, m| m[:order] }.freeze
    end

    private def disability_clauses(suffix)
      {
        'Mental Health Disorder' => a_t["mental_health_problem_#{suffix}".to_sym].eq(1),
        'Alcohol Use Disorder' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(false)),
        'Drug Use Disorder' => a_t["drug_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["alcohol_abuse_#{suffix}".to_sym].eq(false)),
        'Both Alcohol and Drug Use Disorders' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(true)),
        'Chronic Health Condition' => a_t["chronic_disability_#{suffix}".to_sym].eq(1),
        'HIV/AIDS' => a_t["hiv_aids_#{suffix}".to_sym].eq(1),
        'Developmental Disability' => a_t["developmental_disability_#{suffix}".to_sym].eq(1),
        'Physical Disability' => a_t["physical_disability_#{suffix}".to_sym].eq(1),
      }
    end

    # NOTE: HMIS allows for clients to report multiple races. The APR however, does not, and has a single
    # race field. The order that the races appear in the report is encoded in the 'order' of this hash.
    # This practice is very brittle, so we'll copy those here and hard code those relationships
    private def races
      {
        'AmIndAKNative' => {
          order: 4,
          label: 'American Indian, Alaska Native, or Indigenous',
          clause: a_t[:race].eq(race_number('AmIndAKNative')),
        },
        'Asian' => {
          order: 3,
          label: 'Asian or Asian American',
          clause: a_t[:race].eq(race_number('Asian')),
        },
        'BlackAfAmerican' => {
          order: 2,
          label: 'Black, African American, or African',
          clause: a_t[:race].eq(race_number('BlackAfAmerican')),
        },
        'NativeHIPacific' => {
          order: 5,
          label: 'Native Hawaiian or Pacific Islander',
          clause: a_t[:race].eq(race_number('NativeHIPacific')),
        },
        'White' => {
          order: 1,
          label: 'White',
          clause: a_t[:race].eq(race_number('White')),
        },
        'Multiple' => {
          order: 6,
          label: 'Multiple Races',
          clause: a_t[:race].eq(6),
        },
        'Unknown' => {
          order: 7,
          label: "Client Doesn't Know/Client Refused",
          clause: a_t[:race].in([8, 9]),
        },
        'Data Not Collected' => {
          order: 8,
          label: 'Data Not Collected',
          clause: a_t[:race].eq(99),
        },
        'Total' => {
          order: 9,
          label: 'Total',
          clause: Arel.sql('1=1'),
        },
      }.sort_by { |_, m| m[:order] }.freeze
    end

    private def race_fields
      {
        'AmIndAKNative' => 1,
        'Asian' => 2,
        'BlackAfAmerican' => 3,
        'NativeHIPacific' => 4,
        'White' => 5,
      }.freeze
    end

    private def race_number(code)
      race_fields[code]
    end

    def calculate_race(client)
      return client.RaceNone if client.RaceNone.in?([8, 9, 99]) # bad data
      return 6 if client.race_fields.count > 1 # multi-racial
      return 99 if client.race_fields.empty?

      race_number(client.race_fields.first) # return the HUD numeral equivalent
    end

    private def income_types(suffix)
      {
        'Earned Income' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Earned: 1 } } },
        'Unemployment Insurance' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Unemployment: 1 } } },
        'Supplemental Security Income (SSI)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SSI: 1 } } },
        'Social Security Disability Insurance (SSDI)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SSDI: 1 } } },
        'VA Service – Connected Disability Compensation' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { VADisabilityService: 1 } } },
        'VA Non-Service Connected Disability Pension' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { VADisabilityNonService: 1 } } },
        'Private Disability Insurance' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { PrivateDisability: 1 } } },
        "Worker's Compensation" => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { WorkersComp: 1 } } },
        'Temporary Assistance for Needy Families (TANF)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANF: 1 } } },
        'General Assistance (GA)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { GA: 1 } } },
        'Retirement Income from Social Security' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SocSecRetirement: 1 } } },
        'Pension or retirement income from a former job' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Pension: 1 } } },
        'Child Support' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { ChildSupport: 1 } } },
        'Alimony and other spousal support' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Alimony: 1 } } },
        'Other Source' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherIncomeSource: 1 } } },
        'Adults with Income Information at Start and Annual Assessment/Exit' => a_t['income_from_any_source_at_start'].in([0, 1]).and(a_t["income_from_any_source_at_#{suffix}"].in([0, 1])),
      }
    end

    private def non_cash_benefit_types(suffix)
      {
        'Supplemental Nutrition Assistance Program (SNAP) (Previously known as Food Stamps)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SNAP: 1 } } },
        'Special Supplemental Nutrition Program for Women, Infants, and Children (WIC)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { WIC: 1 } } },
        'TANF Child Care Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFChildCare: 1 } } },
        'TANF Transportation Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFTransportation: 1 } } },
        'Other TANF-Funded Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherTANF: 1 } } },
        'Other Source' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherBenefitsSource: 1 } } },
      }
    end

    # Assessments are only collected (and reported on) for HoH
    # Return the most_recent assessment completed for the latest enrollment
    # where the assessment occurred within the report range
    # NOTE: there _should_ always be one of these based on the enrollment_scope and client_scope
    private def latest_ce_assessment(she_enrollment, hoh_enrollment)
      enrollment = if she_enrollment.enrollment.assessments.present?
        she_enrollment
      else
        hoh_enrollment
      end
      enrollment.enrollment.assessments.
        select { |a| a.AssessmentDate.present? && a.AssessmentDate.between?(@report.start_date, @report.end_date) }.
        max_by(&:AssessmentDate)
    end

    private def first_ce_assessment_within_90_days_after_report_range(she_enrollment)
      she_enrollment.enrollment.assessments.
        select { |a| a.AssessmentDate.present? && a.AssessmentDate.between?(@report.end_date, @report.end_date + 90.days) }.
        min_by(&:AssessmentDate)
    end

    # Returns the appropriate CE Event for the client
    # Search for [Coordinated Entry Event] (4.20) records assigned to the same head of household with a [date of event] (4.20.1) where all of the following are
    # true:
    # a. [Date of event] >= [date of assessment] from step 1
    # b. [Date of event] <= ([report end date] + 90 days)
    # c. [Date of event] < Any [dates of assessment] which are between [report end date] and ([report end date] + 90 days)
    # Refer to the example below for clarification.
    # 4. For each client, if any of the records found belong to the same [project id] (2.02.1) as the CE assessment from step 1, use the latest of those to report the
    # client in the table above.
    # 5. If, for a given client, none of the records found belong to the same [project id] as the CE assessment from step 1, use the latest of those to report the client in the table above.
    # 6. The intention of the criteria is to locate the most recent logically relevant record pertaining to the CE assessment record reported in Q9a and Q9b by giving preference to data entered by the same project.
    private def latest_ce_event(she_enrollment, hoh_enrollment, ce_latest_assessment)
      # FIXME:
      # need first assessment after report end if it occurred within 90 days of report end
      # exclude events after that assessment if it exists
      enrollment = if she_enrollment.enrollment.assessments.present?
        she_enrollment
      else
        hoh_enrollment
      end
      potential_events = enrollment.client.source_events.select do |e|
        next_assessment = first_ce_assessment_within_90_days_after_report_range(she_enrollment)
        if ce_latest_assessment
          start_date_check = ce_latest_assessment.AssessmentDate
          end_date_check = [@report.end_date + 90.days, next_assessment&.AssessmentDate].compact.min
        else
          start_date_check = @report.start_date
          end_date_check = @report.end_date
        end
        e.EventDate.present? && e.EventDate.between?(
          start_date_check,
          end_date_check,
        )
      end
      events_from_project = potential_events.select do |e|
        e.enrollment.project.id == she_enrollment.project.id
      end
      return events_from_project.max_by(&:EventDate) if events_from_project.present?

      potential_events.max_by(&:EventDate)
    end
  end
end
