###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.title
      'Coordinated Entry Annual Performance Report - FY 2020'
    end

    def self.short_name
      'CE-APR'
    end

    def url
      hud_reports_ce_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      HudApr::Filters::AprFilter
    end

    def self.questions
      [
        HudApr::Generators::CeApr::Fy2020::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::CeApr::Fy2020::QuestionFive, # Report Validations
        HudApr::Generators::CeApr::Fy2020::QuestionSix, # Data Quality
        HudApr::Generators::CeApr::Fy2020::QuestionSeven, # Persons Served
        HudApr::Generators::CeApr::Fy2020::QuestionEight, # Households Served
        HudApr::Generators::CeApr::Fy2020::QuestionNine, # Participation in Coordinated Entry
        HudApr::Generators::CeApr::Fy2020::QuestionTen, # Total Coordinated Entry Activity During the Year
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end

    # NOTE: Questions 4 through 9
    # Clients in any HMIS project using Method 2 - Active Clients by Date of Service where the enrollment has data in element 4.19 (CE Assessment) with a Date of Assessment in the date range of the report.
    # When including CE Events (element 4.20) for these clients, the system should include data up to 90 days past the report end date. Detailed instructions for this are found on 9c and 9d.
    # Unless otherwise instructed, use data from the enrollment with the latest assessment.
    # Include household members attached to the head of household’s enrollment who were active at the time of that latest assessment, as determined by the household members’ entry and exit dates.

    # Question 10
    # The universe of data for this question is expanded to include all CE activity during the report date range. This includes data in elements 4.19 (CE Assessment) and 4.20 (CE Event) regardless of project or enrollment in which the data was collected.

    # This selects just ids for the clients, to ensure uniqueness, but uses select instead of pluck
    # so that we can find in batches.
    # Find any clients that fit the filter criteria _and_ have at least one assessment in their enrollment
    # occurring within the report range
    def client_scope(start_date: @report.start_date, end_date: @report.end_date)
      scope = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: :assessments }).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Assessment.within_range(start_date..end_date))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      she_scope = GrdaWarehouse::ServiceHistoryEnrollment.all
      she_scope = filter_for_projects(she_scope)
      she_scope = filter_for_cocs(she_scope)
      she_scope = filter_for_veteran_status(she_scope)
      she_scope = filter_for_household_type(she_scope)
      she_scope = filter_for_head_of_household(she_scope)
      she_scope = filter_for_age(she_scope)
      she_scope = filter_for_gender(she_scope)
      she_scope = filter_for_race(she_scope)
      she_scope = filter_for_ethnicity(she_scope)
      she_scope = filter_for_sub_population(she_scope)
      scope = scope.merge(she_scope)

      scope.select(:id)
    end
    memoize :client_scope

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(as_t[:AssessmentDate].asc).
        group_by(&:client_id).
        reject { |_, enrollments| nbn_with_no_service?(enrollments.last) }
    end

    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(enrollment: :assessments).
        merge(GrdaWarehouse::Hud::Assessment.within_range(@report.start_date..@report.end_date))
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    # Only include ages for clients who were present on the assessment date
    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].reject do |client|
        client.entry_date > date || client.exit_date.present? && client.exit_date < date
      end.map do |client|
        GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob])
      end
    end

    # Only include clients who were present on the assessment date
    private def household_member_data(enrollment, date)
      # return nil unless enrollment[:head_of_household]

      active_members = households[enrollment.household_id] || []
      active_members.reject do |client|
        client.entry_date > date || client.exit_date.present? && client.exit_date < date
      end
    end

    # Assessments are only collected (and reported on) for HoH
    # Return the most_recent assessment completed for the latest enrollment
    # where the assessment occurred within the report range
    # NOTE: there _should_ always be one of these based on the enrollment_scope and client_scope
    private def latest_ce_assessment(she_enrollment)
      she_enrollment.enrollment.assessments.
        select { |a| a.AssessmentDate.present? && a.AssessmentDate.between(@report.start_date, @report.end_date) }.
        max_by(&:AssessmentDate)
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
    private def latest_ce_event(she_enrollment, ce_latest_assessment)
      potential_events = she_enrollment.client.events.select { |e| e.EventDate.present? && e.EventDate.between(ce_latest_assessment.AssessmentDate, @report.end_date + 90.days) }
      events_from_project = potential_events.select { |e| e.enrollment.project.id == she_enrollment.project.id }
      return events_from_project.max_by(&:EventDate) if events_from_project.present?

      potential_events.max_by(&:EventDate)
    end

    private def add_apr_clients # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
      @generator.client_scope.find_in_batches(batch_size: 100) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)

        # Pre-calculate some values
        household_types = {}
        times_to_move_in = {}
        move_in_dates = {}
        approximate_move_in_dates = {}
        enrollments_by_client_id.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last

          hh_id = get_hh_id(last_service_history_enrollment)
          date = [
            @report.start_date,
            last_service_history_enrollment.first_date_in_program,
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
          ce_latest_assessment = latest_ce_assessment(last_service_history_enrollment)
          ce_latest_event = latest_ce_event(she_enrollment, ce_latest_assessment)
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
            select { |h| h.InformationDate <= @report.end_date }.
            max_by(&:InformationDate)

          last_bed_night = enrollment.services.select do |s|
            s.RecordType == 200 && s.DateProvided < @report.end_date
          end&.max_by(&:DateProvided)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(client_start_date)
          household_type = if age.blank? || age.negative?
            :unknown
          else
            household_types[get_hh_id(last_service_history_enrollment)]
          end

          processed_source_clients << source_client.id
          pending_associations[client] = report_client_universe.new(
            client_id: source_client.id,
            destination_client_id: last_service_history_enrollment.client_id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,

            age: age,
            alcohol_abuse_entry: [1, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_exit: [1, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
            alcohol_abuse_latest: [1, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
            annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
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
            gender: source_client.Gender,
            head_of_household_id: last_service_history_enrollment.head_of_household_id,
            head_of_household: last_service_history_enrollment[:head_of_household],
            hiv_aids_entry: disabilities_at_entry.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids_exit: disabilities_at_exit.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids_latest: disabilities_latest.detect(&:hiv?)&.DisabilityResponse,
            hiv_aids: disabilities.detect(&:hiv?).present?,
            household_id: get_hh_id(last_service_history_enrollment),
            household_members: household_member_data(last_service_history_enrollment, latest_assessment.AssessmentDate),
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
                household_members: household_member_data(last_service_history_enrollment, latest_assessment.AssessmentDate),
                first_date_in_program: last_service_history_enrollment.first_date_in_program,
              ),
            ),
            overlapping_enrollments: overlapping_enrollments(enrollments, last_service_history_enrollment),
            # SHE parenting_youth is computed at entry date, and we need to consider the report start date
            parenting_youth: youth_parent?(
              OpenStruct.new(
                head_of_household: last_service_history_enrollment[:head_of_household],
                household_members: household_member_data(last_service_history_enrollment, latest_assessment.AssessmentDate),
                first_date_in_program: last_service_history_enrollment.first_date_in_program,
              ),
            ),
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
            ce_assessment_date: latest_assessment.AssessmentDate,
            ce_assessment_type: latest_assessment.AssessmentType, # for Q9a
            ce_assessment_prioritization_status: latest_assessment.PrioritizationStatus, # for Q9b, Q9d
            ce_event_date: ce_latest_event.EventDate,
            ce_event_event: ce_latest_event.Event, # Q9c, Q9d
          )
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
          universe_cell.add_universe_members(pending_associations)
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
      end
    end
  end
end
