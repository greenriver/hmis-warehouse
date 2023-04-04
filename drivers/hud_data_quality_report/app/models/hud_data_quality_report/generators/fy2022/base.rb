###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
module HudDataQualityReport::Generators::Fy2022
  class Base < ::HudReports::QuestionBase
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::Destinations
    include HudReports::Veterans
    include HudReports::LengthOfStays
    include HudReports::Incomes

    private def universe
      add_clients unless clients_populated?
      @universe ||= @report.universe(self.class.question_number)
    end

    private def add_clients # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
      client_scope.find_in_batches(batch_size: 100) do |batch|
        # puts 'Batch of clients: '
        # puts GetProcessMem.new.inspect
        enrollments_by_client_id = clients_with_enrollments(batch)

        # Pre-calculate some values
        household_types = {}
        household_assessment_required = {}
        times_to_move_in = {}
        move_in_dates = {}
        approximate_move_in_dates = {}
        dates_to_street = {}
        enrollments_by_client_id.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          enrollment = last_service_history_enrollment.enrollment
          source_client = enrollment.client
          client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max
          age = source_client.age_on(client_start_date)

          hh_id = get_hh_id(last_service_history_enrollment)
          hoh_enrollment = hoh_enrollments[get_hoh_id(hh_id)]
          household_assessment_required[hh_id] = annual_assessment_expected?(hoh_enrollment)
          date = [
            @report.start_date,
            last_service_history_enrollment.first_date_in_program,
          ].max
          household_types[hh_id] = household_makeup(hh_id, date)
          times_to_move_in[last_service_history_enrollment.client_id] = time_to_move_in(last_service_history_enrollment)
          move_in_dates[last_service_history_enrollment.client_id] = appropriate_move_in_date(last_service_history_enrollment)
          approximate_move_in_dates[last_service_history_enrollment.client_id] = approximate_time_to_move_in(last_service_history_enrollment, age, hoh_enrollment)
          dates_to_street[last_service_history_enrollment.client_id] = date_to_street(last_service_history_enrollment, age, hoh_enrollment)
        end

        pending_associations = {}
        processed_source_clients = Set.new
        # Re-shape client to APR Client shape
        batch.each do |client|
          # Fetch enrollments for destination client
          enrollments = enrollments_by_client_id[client.id]
          next unless enrollments.present?

          last_service_history_enrollment = enrollments.last
          enrollment = last_service_history_enrollment.enrollment
          source_client = enrollment.client
          next unless source_client

          client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

          exit_date = last_service_history_enrollment.last_date_in_program
          exit_record = last_service_history_enrollment.enrollment if exit_date.present? && exit_date < report_end_date

          hh_id = get_hh_id(last_service_history_enrollment)
          # Fetch the Head of Household's enrollment, but if we don't have a head, just use ours
          hoh_enrollment = hoh_enrollments[get_hoh_id(hh_id)] || last_service_history_enrollment

          income_at_start = enrollment.income_benefits_at_entry
          income_at_annual_assessment = annual_assessment(enrollment, hoh_enrollment.first_date_in_program)
          income_at_exit = exit_record&.income_benefits_at_exit

          disabilities = enrollment.disabilities.select { |disability| [1, 2, 3].include?(disability.DisabilityResponse) }

          disabilities_at_entry = enrollment.disabilities.select { |d| d.DataCollectionStage == 1 }
          disabilities_at_exit = enrollment.disabilities.select { |d| d.DataCollectionStage == 3 }
          max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= report_end_date }.
            map(&:InformationDate).max
          disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

          # Need to sort by information date, then DateUpdated to catch the most-recent
          # added for the Datalab test kit
          health_and_dv = enrollment.health_and_dvs.
            select do |h|
              h.InformationDate <= @report.end_date && !h.DomesticViolenceVictim.nil?
            end.
            max_by { |h| [h.InformationDate, h.DateUpdated] }

          last_bed_night = enrollment.services.select do |s|
            s.RecordType == 200 && s.DateProvided < report_end_date
          end&.max_by(&:DateProvided)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(client_start_date)
          household_type = household_types[hh_id]
          hoh_anniversary_date = anniversary_date(entry_date: hoh_enrollment.first_date_in_program, report_end_date: @report.end_date)
          annual_assessment_expected = if age.present? && age >= 18
            household_assessment_required[hh_id] && last_service_history_enrollment.first_date_in_program < hoh_anniversary_date
          else
            household_assessment_required[hh_id]
          end

          processed_source_clients << source_client.id
          pending_associations[client] = report_client_universe.new(
            client_id: source_client.id,
            destination_client_id: last_service_history_enrollment.client_id,
            personal_id: source_client.PersonalID,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,

            age: age,
            alcohol_abuse_entry: [1, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_exit: [1, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_latest: [1, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
            annual_assessment_expected: annual_assessment_expected,
            # anniversary dates are always based on HoH enrollment
            annual_assessment_in_window: annual_assessment_in_window?(hoh_enrollment, income_at_annual_assessment&.InformationDate),
            approximate_time_to_move_in: approximate_move_in_dates[last_service_history_enrollment.client_id],
            came_from_street_last_night: enrollment.PreviousStreetESSH,
            chronic_disability_entry: disabilities_at_entry.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability_exit: disabilities_at_exit.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability_latest: disabilities_latest.detect(&:chronic?)&.DisabilityResponse,
            chronic_disability: disabilities.detect(&:chronic?).present?,
            chronically_homeless: last_service_history_enrollment.enrollment.chronically_homeless_at_start?,
            currently_fleeing: health_and_dv&.CurrentlyFleeing,
            date_homeless: enrollment.DateToStreetESSH,
            date_of_engagement: last_service_history_enrollment.enrollment.DateOfEngagement,
            date_of_last_bed_night: last_bed_night&.DateProvided,
            date_to_street: dates_to_street[last_service_history_enrollment.client_id],
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
            household_members: household_member_data(last_service_history_enrollment),
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
            # NOTE: this is used for data quality, and should only look at the most recent disability
            indefinite_and_impairs: disabilities_latest.detect(&:indefinite_and_impairs?),
            insurance_from_any_source_at_annual_assessment: income_at_annual_assessment&.InsuranceFromAnySource,
            insurance_from_any_source_at_exit: income_at_exit&.InsuranceFromAnySource,
            insurance_from_any_source_at_start: income_at_start&.InsuranceFromAnySource,
            last_date_in_program: last_service_history_enrollment.last_date_in_program,
            last_name: source_client.LastName,
            length_of_stay: stay_length(last_service_history_enrollment),

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
            other_clients_over_25: last_service_history_enrollment.other_clients_over_25,
            overlapping_enrollments: overlapping_enrollments(enrollments, last_service_history_enrollment),
            parenting_youth: last_service_history_enrollment.parenting_youth,
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
          )
        end

        # Import clients
        result = report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
            validate: false,
          },
        )
        clients = report_client_universe.where(id: result.ids)

        # Attach clients to relevant questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          universe_cell.add_universe_members(pending_associations)
        end

        # Add any associated data that needs to be linked back to the clients
        client_living_situations = []
        clients.each do |dq_client|
          last_enrollment = enrollments_by_client_id[dq_client.destination_client_id].last.enrollment
          situations = last_enrollment.current_living_situations
          engagement_date = last_enrollment.DateOfEngagement
          # If we're looking at SO and don't have a CLS on the engagement date,
          # add one of type "37" - "Worker unable to determine" because it doesn't count as missing.
          if last_enrollment.project.so? && engagement_date.present? && ! situations.detect { |cls| cls.InformationDate == engagement_date }
            client_living_situations << dq_client.hud_report_dq_living_situations.build(
              information_date: engagement_date,
              living_situation: 37,
            )
          end
          situations.each do |living_situation|
            client_living_situations << dq_client.hud_report_dq_living_situations.build(
              information_date: living_situation.InformationDate,
              living_situation: 37,
            )
          end
        end
        GC.start
        report_living_situation_universe.import(client_living_situations, validate: false)
      end
    end

    private def clients_populated?
      @report.report_cells.joins(universe_members: :dq_client).exists?
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
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
        service_within_date_range(start_date: @report.start_date, end_date: @report.end_date).
        where(service_history_enrollment_id: enrollment_scope_without_preloads.select(:id)).
        pluck(:service_history_enrollment_id).to_set

      @with_service.include?(enrollment.id)
    end

    private def engaged?(enrollment)
      return true unless enrollment.so?
      return false if enrollment.enrollment.DateOfEngagement.blank?

      enrollment.enrollment.DateOfEngagement < @report.end_date
    end

    private def engaged_clause
      a_t[:project_type].not_eq(4).or(
        a_t[:project_type].eq(4).
        and(a_t[:date_of_engagement].lt(@report.end_date).
        and(a_t[:date_of_engagement].not_eq(nil))),
      )
    end

    private def enrollment_scope
      preloads = {
        enrollment: [
          :client,
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
        ],
      }
      enrollment_scope_without_preloads.preload(preloads)
    end

    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(:enrollment).
        left_outer_joins(enrollment: :enrollment_coc_at_entry).
        merge(
          GrdaWarehouse::Hud::EnrollmentCoc.where(CoCCode: @report.coc_codes).
          or(GrdaWarehouse::Hud::EnrollmentCoc.where(CoCCode: nil)).
          or(GrdaWarehouse::Hud::EnrollmentCoc.where.not(CoCCode: HudUtility.cocs.keys)),
        )
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    delegate :client_scope, to: :@generator
    delegate :end_date, to: :@report, prefix: :report

    private def report_client_universe
      HudDataQualityReport::Fy2020::DqClient
    end

    private def report_living_situation_universe
      HudDataQualityReport::Fy2020::DqLivingSituation
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
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

    #  HMIS allows for clients to report multiple races. The APR however, does not, and has a single
    # race field.
    def calculate_race(client)
      return client.RaceNone if client.RaceNone.in?([8, 9, 99]) # bad data
      return 6 if client.race_fields.count > 1 # multi-racial
      return 99 if client.race_fields.empty?

      race_number(client.race_fields.first) # return the HUD numeral equivalent
    end
  end
end
