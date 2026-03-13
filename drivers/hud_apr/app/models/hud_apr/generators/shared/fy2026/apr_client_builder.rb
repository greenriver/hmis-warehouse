# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026
  class AprClientBuilder
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Destinations
    include HudReports::Veterans
    include HudReports::LengthOfStays
    include HudReports::Incomes

    HohEnrollmentProxy = Data.define(:entry_date, :first_date_in_program, :head_of_household?, :enrollment)
    HohEnrollmentProxyInner = Data.define(:DateToStreetESSH) # rubocop:disable Naming/MethodName

    attr_reader :last_service_history_enrollment, :ctx, :source_client

    private def a_t
      @a_t ||= HudApr::Fy2020::AprClient.arel_table
    end

    # @param report [HudReports::ReportInstance] The report instance currently being generated.
    # @param client [GrdaWarehouse::Hud::Client] The unified destination client record.
    # @param enrollments [Array<GrdaWarehouse::ServiceHistoryEnrollment>] All enrollments for this client.
    # @param context_map [Hash<Integer, HudReports::HouseholdContext>] A map of ServiceHistoryEnrollment IDs to
    #   their pre-computed household-level business logic.
    # @param hoh_enrollment_map [Hash<Integer, GrdaWarehouse::ServiceHistoryEnrollment>] A map of
    #   ServiceHistoryEnrollment IDs for Head of Households to their raw records with preloaded associations.
    # @param needs_ce_assessments [Boolean] Whether to process Coordinated Entry specific logic and attributes.
    # @param households [Hash<Array(String, Integer), Array<Hash>>] A map of [household_id, data_source_id] to
    #   legacy member hashes for all members in that household.
    def initialize(report:, client:, enrollments:, context_map:, hoh_enrollment_map:, needs_ce_assessments:, households:)
      @report = report
      @client = client # Destination client
      @raw_enrollments = Array(enrollments)
      @context_map = context_map
      @hoh_enrollment_map = hoh_enrollment_map
      @needs_ce_assessments = needs_ce_assessments
      @households = households
    end

    def self.build(...)
      new(...).resolve_and_build
    end

    def resolve_and_build
      resolve_primary_enrollment!

      return { success: false } unless @last_service_history_enrollment && resolve_enrollment_coc!

      raise ArgumentError, "Missing context for SHE #{@last_service_history_enrollment.id}" unless @ctx
      raise ArgumentError, "Missing source client for SHE #{@last_service_history_enrollment.id}" unless @source_client

      {
        success: true,
        attributes: build_attributes_internal,
        source_client_id: @source_client.id,
        enrollment_id: @last_service_history_enrollment.enrollment.id,
      }
    end

    private

    def build_attributes_internal
      options = map_standard_attributes
      options.merge!(map_ce_attributes) if @needs_ce_assessments
      options
    end

    def resolve_primary_enrollment!
      @last_service_history_enrollment = @raw_enrollments.last
      return unless @last_service_history_enrollment

      @ctx = @context_map[@last_service_history_enrollment.id]
      return unless @ctx

      @hoh_enrollment = @hoh_enrollment_map[@ctx.hoh_service_history_enrollment_id]

      if @needs_ce_assessments
        # CE logic requires a full HoH enrollment. If we don't have one, fall back to current.
        hoh_for_ce = @hoh_enrollment || @last_service_history_enrollment
        @ce_latest_assessment = latest_ce_assessment(@last_service_history_enrollment, hoh_for_ce)
        @ce_latest_event = latest_ce_event(@last_service_history_enrollment, hoh_for_ce, @ce_latest_assessment)

        # Adjust last service history enrollment if falls outside assessment date
        if @ce_latest_assessment.present?
          @last_service_history_enrollment = @raw_enrollments.select do |e|
            @ce_latest_assessment.AssessmentDate.between?(
              e.first_date_in_program,
              e.last_date_in_program || @report.end_date,
            )
          end.last

          # Try to get context for the newly selected enrollment. Fall back to the original
          # @ctx if the new enrollment has no entry in the map (e.g. it falls outside the
          # report universe but is the closest match for the CE assessment date).
          @ctx = @context_map[@last_service_history_enrollment.id] || @ctx if @last_service_history_enrollment
        end
      end

      return unless @last_service_history_enrollment

      @enrollment = @last_service_history_enrollment.enrollment
      @source_client = @enrollment&.client
    end

    # Resolves the effective CoC for the enrollment (step 6 of CE APR universe rules) and
    # stores it in @calculated_enrollment_coc for use in map_standard_attributes.
    # Returns true if the resolved CoC is in the report's chosen set (step 7), false otherwise.
    def resolve_enrollment_coc!
      # If the project only operates in one CoC, use that directly.
      # Otherwise prefer the pre-computed HoH CoC from context, falling back to the
      # HoH enrollment record, then the enrollment's own CoC field.
      @calculated_enrollment_coc = if @enrollment.project.project_cocs.one?
        @enrollment.project.project_cocs.first.coc_code
      else
        @ctx.hoh_coc || @hoh_enrollment&.enrollment&.enrollment_coc || @enrollment.EnrollmentCoC
      end

      @calculated_enrollment_coc.in?(@report.coc_codes)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def map_standard_attributes
      exit_date = @last_service_history_enrollment.last_date_in_program
      exited_enrollment = @last_service_history_enrollment.enrollment if exit_date.present? && exit_date <= @report.end_date

      income_at_start = @enrollment.income_benefits_at_entry
      hoh_entry_date = @ctx.hoh_entry_date || @hoh_enrollment&.first_date_in_program || @last_service_history_enrollment.first_date_in_program
      income_at_annual_assessment = annual_assessment(@enrollment, hoh_entry_date)
      income_at_exit = exited_enrollment&.income_benefits_at_exit

      disabilities = @enrollment.disabilities.select { |disability| [1, 2, 3].include?(disability.DisabilityResponse) }
      disabilities_at_entry = @enrollment.disabilities.select { |d| d.DataCollectionStage == 1 }
      disabilities_at_exit = @enrollment.disabilities.select { |d| d.DataCollectionStage == 3 }
      max_disability_date = @enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.map(&:InformationDate).max
      disabilities_latest = @enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

      # Need to sort by information date, then DateUpdated to catch the most-recent
      # added for the Datalab test kit
      health_and_dv = @enrollment.health_and_dvs.select do |h|
        h.InformationDate && h.InformationDate <= @report.end_date && !h.DomesticViolenceSurvivor.nil?
      end.max_by { |h| [h.InformationDate, h.DateUpdated] }

      last_bed_night = @enrollment.services.select do |service|
        service.RecordType == 200 && service.DateProvided && service.DateProvided < @report.end_date
      end&.max_by(&:DateProvided)

      move_on_assistance = @enrollment.services.select do |service|
        service.RecordType == 300 && service.DateProvided && service.DateProvided < @report.end_date
      end&.max_by(&:DateProvided)

      youth_education_status_at_entry = @enrollment.youth_education_statuses.filter do |status|
        status.DataCollectionStage == 1 && status.InformationDate && status.InformationDate < @report.end_date
      end&.max_by(&:InformationDate)

      youth_education_status_at_exit = @enrollment.youth_education_statuses.filter do |status|
        status.DataCollectionStage == 3 && status.InformationDate && status.InformationDate < @report.end_date
      end&.max_by(&:InformationDate)

      # Age is pre-computed in HouseholdContext as of [entry_date, report_start].max per HUD rules.
      age = @ctx.age
      hoh_anniversary_date = anniversary_date(entry_date: hoh_entry_date, report_end_date: @report.end_date)
      hoh_light = @hoh_enrollment || begin
        hoh_enrollment_proxy = HohEnrollmentProxyInner.new(@ctx.hoh_date_to_street)
        HohEnrollmentProxy.new(
          entry_date: hoh_entry_date,
          first_date_in_program: hoh_entry_date,
          "head_of_household?": true,
          enrollment: hoh_enrollment_proxy,
        )
      end

      # Households with required assessments are calculated earlier for performance reasons.
      # An APR is being submitted to verify assessment requirements for non-HoH adults entering the HH at a different date than the HoH.
      # e.g. If an adult enters 1 day prior HoH assessment date, is their assessment required on the HoH date (1 day later) or on the following year (1 year + 1 day later)
      #      If an adult enters 1 day after the HoH assessment date is their assessment due on the HoH date (1 year - 1 day later) or on the following year (2 years - 1 day)
      annual_assessment_expected = if age.present? && age >= 18
        annual_assessment_expected?(hoh_enrollment: hoh_light, enrollment: @last_service_history_enrollment, report_end_date: @report.end_date) &&
          @last_service_history_enrollment.first_date_in_program < hoh_anniversary_date
      else
        annual_assessment_expected?(hoh_enrollment: hoh_light, enrollment: @last_service_history_enrollment, report_end_date: @report.end_date)
      end

      destination = @last_service_history_enrollment.destination
      destination_subsidy_type = exited_enrollment&.exit&.DestinationSubsidyType
      destination = 99 if destination == 435 && !destination_subsidy_type.in?(HudHelper.util('2026').rental_subsidy_types.keys)
      destination = 99 unless HudHelper.util('2026').valid_destinations.key?(destination)

      {
        client_id: @source_client.id,
        destination_client_id: @client.id,
        data_source_id: @source_client.data_source_id,
        personal_id: @source_client.PersonalID,
        project_id: @last_service_history_enrollment.project.id,
        report_instance_id: @report.id,
        source_enrollment_id: @enrollment.id,

        age: age,
        alcohol_abuse_entry: [1, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
        alcohol_abuse_exit: [1, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
        alcohol_abuse_latest: [1, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
        annual_assessment_expected: annual_assessment_expected,
        annual_assessment_in_window: annual_assessment_in_window?(hoh_light, income_at_annual_assessment&.InformationDate),
        approximate_time_to_move_in: approximate_time_to_move_in(@last_service_history_enrollment, age, hoh_light),
        came_from_street_last_night: @enrollment.PreviousStreetESSH,
        chronic_disability_entry: disabilities_at_entry.detect(&:chronic?)&.DisabilityResponse,
        chronic_disability_exit: disabilities_at_exit.detect(&:chronic?)&.DisabilityResponse,
        chronic_disability_latest: disabilities_latest.detect(&:chronic?)&.DisabilityResponse,
        chronic_disability: disabilities.detect(&:chronic?).present?,
        chronically_homeless: @ctx.inherited_chronic_status,
        chronically_homeless_detail: @ctx.inherited_chronic_detail,
        currently_fleeing: health_and_dv&.CurrentlyFleeing,
        date_homeless: @enrollment.DateToStreetESSH,
        date_of_engagement: @enrollment.DateOfEngagement,
        date_of_last_bed_night: last_bed_night&.DateProvided,
        move_on_assistance_provided: move_on_assistance&.TypeProvided,

        current_school_attend_at_entry: youth_education_status_at_entry&.CurrentSchoolAttend,
        most_recent_ed_status_at_entry: youth_education_status_at_entry&.MostRecentEdStatus,
        current_ed_status_at_entry: youth_education_status_at_entry&.CurrentEdStatus,

        current_school_attend_at_exit: youth_education_status_at_exit&.CurrentSchoolAttend,
        most_recent_ed_status_at_exit: youth_education_status_at_exit&.MostRecentEdStatus,
        current_ed_status_at_exit: youth_education_status_at_exit&.CurrentEdStatus,

        los_under_threshold: @enrollment.LOSUnderThreshold,
        date_to_street: date_to_street(@last_service_history_enrollment, age, hoh_light),
        destination: destination,
        developmental_disability_entry: disabilities_at_entry.detect(&:developmental?)&.DisabilityResponse,
        developmental_disability_exit: disabilities_at_exit.detect(&:developmental?)&.DisabilityResponse,
        developmental_disability_latest: disabilities_latest.detect(&:developmental?)&.DisabilityResponse,
        developmental_disability: disabilities.detect(&:developmental?).present?,
        disabling_condition: @enrollment.DisablingCondition,
        dob_quality: apr_client_dob_quality(@source_client),
        dob: @source_client.DOB,
        client_created_at: @source_client.DateCreated || @source_client.DateUpdated || DateTime.current,
        domestic_violence: health_and_dv&.DomesticViolenceSurvivor,
        domestic_violence_occurred: health_and_dv&.WhenOccurred,
        drug_abuse_entry: [2, 3].include?(disabilities_at_entry.detect(&:substance?)&.DisabilityResponse),
        drug_abuse_exit: [2, 3].include?(disabilities_at_exit.detect(&:substance?)&.DisabilityResponse),
        drug_abuse_latest: [2, 3].include?(disabilities_latest.detect(&:substance?)&.DisabilityResponse),
        enrollment_coc: @calculated_enrollment_coc,
        enrollment_created: @enrollment.DateCreated || @enrollment.DateUpdated || DateTime.current,
        exit_created: exited_enrollment&.exit&.DateCreated,
        exit_destination_subsidy_type: destination_subsidy_type,
        first_date_in_program: @last_service_history_enrollment.first_date_in_program,
        first_name: @source_client.FirstName,
        sex: @source_client.Sex || 99,
        head_of_household_id: @ctx.hoh_personal_id,
        head_of_household: @ctx.is_hoh,
        hiv_aids_entry: disabilities_at_entry.detect(&:hiv?)&.DisabilityResponse,
        hiv_aids_exit: disabilities_at_exit.detect(&:hiv?)&.DisabilityResponse,
        hiv_aids_latest: disabilities_latest.detect(&:hiv?)&.DisabilityResponse,
        hiv_aids: disabilities.detect(&:hiv?).present?,
        household_id: @ctx.household_id,
        household_members: @households[[@ctx.household_id, @ctx.data_source_id]] || [],
        household_type: @ctx.household_type,
        housing_assessment: @enrollment.exit&.HousingAssessment,
        income_date_at_annual_assessment: income_at_annual_assessment&.InformationDate,
        income_date_at_exit: income_at_exit&.InformationDate,
        income_date_at_start: income_at_start&.InformationDate,

        # Income from any source needs to be present in both a "cleaned" form and a "raw" form
        # The cleaned form ensures alignment between IncomeFromAnySource and the calculated TotalMonthlyIncome
        # as noted in the HMIS Glossary under the Determining Total and Earned Income section

        # raw
        income_from_any_source_at_annual_assessment_raw: income_at_annual_assessment&.IncomeFromAnySource,
        income_from_any_source_at_exit_raw: income_at_exit&.IncomeFromAnySource,
        income_from_any_source_at_start_raw: income_at_start&.IncomeFromAnySource,

        # cleaned
        income_from_any_source_at_annual_assessment: income_at_annual_assessment&.hud_income_from_any_source,
        income_from_any_source_at_exit: income_at_exit&.hud_income_from_any_source,
        income_from_any_source_at_start: income_at_start&.hud_income_from_any_source,
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
        last_date_in_program: @last_service_history_enrollment.last_date_in_program,
        last_name: @source_client.LastName,
        length_of_stay: stay_length(@last_service_history_enrollment),
        bed_nights: bed_nights(@last_service_history_enrollment),
        mental_health_problem_entry: disabilities_at_entry.detect(&:mental?)&.DisabilityResponse,
        mental_health_problem_exit: disabilities_at_exit.detect(&:mental?)&.DisabilityResponse,
        mental_health_problem_latest: disabilities_latest.detect(&:mental?)&.DisabilityResponse,
        mental_health_problem: disabilities.detect(&:mental?).present?,
        months_homeless: @enrollment.MonthsHomelessPastThreeYears,
        move_in_date: @last_service_history_enrollment.move_in_date,
        hoh_move_in_date: @ctx.hoh_move_in_date,
        adjusted_move_in_date: begin
          calculated_move_in_date = @ctx.inherited_move_in_date
          is_ph_or_pfs_project = @last_service_history_enrollment.ph? ||
            (@last_service_history_enrollment.other? && @enrollment.project.pay_for_success?)
          calculated_move_in_date || (is_ph_or_pfs_project ? nil : @last_service_history_enrollment.first_date_in_program)
        end,
        name_quality: @source_client.NameDataQuality,
        non_cash_benefits_from_any_source_at_annual_assessment: income_at_annual_assessment&.BenefitsFromAnySource,
        non_cash_benefits_from_any_source_at_exit: income_at_exit&.BenefitsFromAnySource,
        non_cash_benefits_from_any_source_at_start: income_at_start&.BenefitsFromAnySource,
        other_clients_over_25: @ctx.has_other_clients_over_25,
        overlapping_enrollments: overlapping_enrollments(@raw_enrollments, @last_service_history_enrollment),
        parenting_youth: @ctx.is_parenting_youth,
        pit_enrollments: pit_enrollment_info(@raw_enrollments, @context_map),
        physical_disability_entry: disabilities_at_entry.detect(&:physical?)&.DisabilityResponse,
        physical_disability_exit: disabilities_at_exit.detect(&:physical?)&.DisabilityResponse,
        physical_disability_latest: disabilities_latest.detect(&:physical?)&.DisabilityResponse,
        physical_disability: disabilities.detect(&:physical?).present?,
        prior_length_of_stay: @enrollment.LengthOfStay,
        prior_living_situation: @enrollment.LivingSituation,
        project_tracking_method: @last_service_history_enrollment.project_tracking_method,
        project_type: @last_service_history_enrollment.project_type,
        race_multi: @source_client.race_multi.sort.join(','),
        # For data quality checks, we want all data instead of filtering out RaceNone responses when additional race data is included.
        # HMIS Reporting Glossary Reference: Data Quality - Q2: include records with an 8 or 9 indicated even if there is also a value of 1, 2, 3, 4, 5, 6, or 7 in the same field
        race_multi_include_race_none: @source_client.race_multi_include_race_none.sort,
        relationship_to_hoh: @enrollment.RelationshipToHoH,
        sexual_orientation: @enrollment.sexual_orientation,
        ssn_quality: @source_client.SSNDataQuality,
        ssn: @source_client.SSN,
        subsidy_information: @enrollment.exit&.SubsidyInformation,
        substance_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse,
        substance_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse,
        substance_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse,
        substance_abuse: disabilities.detect(&:substance?).present?,
        time_to_move_in: time_to_move_in(@last_service_history_enrollment),
        times_homeless: @enrollment.TimesHomelessPastThreeYears,
        translation_needed: @enrollment.TranslationNeeded,
        preferred_language: @enrollment.PreferredLanguage,
        preferred_language_different: @enrollment.PreferredLanguageDifferent,
        veteran_status: @source_client.VeteranStatus,
        pay_for_success: @enrollment.project.pay_for_success?,
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def map_ce_attributes
      {
        ce_assessment_date: @ce_latest_assessment&.AssessmentDate,
        ce_assessment_type: @ce_latest_assessment&.AssessmentType, # for Q9a
        ce_assessment_prioritization_status: @ce_latest_assessment&.PrioritizationStatus, # for Q9b, Q9d
        ce_event_date: @ce_latest_event&.EventDate,
        ce_event_event: @ce_latest_event&.Event, # Q9c, Q9d
        ce_event_problem_sol_div_rr_result: @ce_latest_event&.ProbSolDivRRResult,
        ce_event_referral_case_manage_after: @ce_latest_event&.ReferralCaseManageAfter,
        ce_event_referral_result: @ce_latest_event&.ReferralResult,
      }
    end

    # Assessments are only collected (and reported on) for HoH
    # Return the most_recent assessment completed for the latest enrollment
    # where the assessment occurred within the report range
    # NOTE: there _should_ always be one of these based on the enrollment_scope and client_scope
    def latest_ce_assessment(she_enrollment, hoh_enrollment)
      range = @report.start_date..@report.end_date
      assessments = valid_ce_assessment(she_enrollment, range).presence || valid_ce_assessment(hoh_enrollment, range)
      assessments.max_by(&:AssessmentDate)
    end

    def valid_ce_assessment(she, range)
      she.enrollment.assessments.select do |a|
        in_report_range = a.AssessmentDate.present? && a.AssessmentDate.between?(range.first, range.last)
        in_ce_participation_range = a.enrollment.project.participating_in_ce_on?(a.AssessmentDate)
        in_report_range && in_ce_participation_range
      end
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
    def latest_ce_event(latest_she_for_client, latest_enrollment_for_hoh, latest_ce_assessment)
      # If the client doesn't have any CE events, use the HoH to look for events
      client = if latest_she_for_client.client.source_events.present?
        latest_she_for_client.client
      else
        latest_enrollment_for_hoh.client
      end
      return unless client.present?

      # 1. Determine the [date of assessment] (4.19.1) from the latest [Coordinated Entry Assessment] (4.19) for each household in the report universe as described in the report universe instructions and the determining latest assessment instructions.
      # already determined using `latest_ce_assessment`

      max_assessment_date_post_report_end_date = client.source_assessments.map(&:AssessmentDate).select do |d|
        d.present? && d.between?(@report.end_date, @report.end_date + 90.days)
      end.max

      # 2. For all source event for the client
      potential_events = client.source_events.select do |event|
        # because we are using a preload, we don't filter earlier events in the SQL, make sure they all occur
        # on or after the report start
        next false if event.EventDate <= @report.start_date
        # Everyone _should_ have a CE Assessment, but occassionally we get someone who doesn't have one
        next false if latest_ce_assessment.blank? || latest_ce_assessment.AssessmentDate.blank?

        # 2.a [Date of event] >= [date of assessment] from step 1
        after_assessment = event.EventDate >= latest_ce_assessment.AssessmentDate
        # 2.b Date of event] <= ([report end date] + 90 days)
        within_90_days_of_report_end = event.EventDate <= (@report.end_date + 90.days)
        # 2.c [Date of event] < Any [dates of assessment] which are between [report end date] and ([report end date] + 90 days)
        before_next_assessment = max_assessment_date_post_report_end_date.blank? || event.EventDate < max_assessment_date_post_report_end_date
        project_ce_participating = event.enrollment.project.participating_in_ce_on?(event.EventDate)

        after_assessment && within_90_days_of_report_end && before_next_assessment && project_ce_participating
      end

      # 3. For each client, if any of the records found belong to the same [project id] (2.02.1) as the CE assessment from step 1, use the latest of those to report the client in the table above.
      events_from_project = potential_events.select do |event|
        event.enrollment.project.id == latest_ce_assessment.enrollment.project.id
      end
      return events_from_project.max_by(&:EventDate) if events_from_project.present?

      # 4. If, for a given client, none of the records found belong to the same [project id] (2.02.1) as the CE assessment from step 1, use the latest of those to report the client in the table above.
      potential_events.max_by(&:EventDate)
    end

    def apr_client_dob_quality(source_client)
      return source_client.DOBDataQuality if source_client.DOB.present? && source_client.DOBDataQuality.in?([1, 2])
      return source_client.DOBDataQuality if source_client.DOB.blank? && source_client.DOBDataQuality.in?([8, 9, 99])

      99
    end

    def pit_enrollment_info(enrollments, contexts_by_she_id)
      pit_dates = [1, 4, 7, 10].map { |month| pit_date(month: month, before: @report.end_date) }
      pit_dates.map do |pit_date|
        enrollments_for_date = enrollments.select do |enrollment|
          enrolled = if enrollment.project_type.in?([3, 13]) || enrollment.enrollment.project.pay_for_success?
            move_in_date = contexts_by_she_id[enrollment.id]&.inherited_move_in_date
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program > pit_date) &&
              move_in_date.present? &&
              move_in_date <= pit_date &&
              move_in_date >= enrollment.first_date_in_program
          elsif enrollment.project_type.in?([0, 1, 2, 8, 9, 10])
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program > pit_date)
          else
            enrollment.first_date_in_program <= pit_date &&
              (enrollment.last_date_in_program.nil? || enrollment.last_date_in_program >= pit_date)
          end
          next false unless enrolled
          next true if enrollment.project_type != 1 || enrollment.project_tracking_method != 3

          enrollment.service_history_services.bed_night.on_date(pit_date).exists?
        end.map do |enrollment|
          {
            first_date_in_program: enrollment.first_date_in_program,
            last_date_in_program: enrollment.last_date_in_program,
            project_type: enrollment.project_type,
            project_tracking_method: enrollment.project_tracking_method,
            move_in_date: contexts_by_she_id[enrollment.id]&.inherited_move_in_date,
            relationship_to_hoh: enrollment.enrollment.relationship_to_hoh,
          }
        end
        [pit_date, enrollments_for_date]
      end.to_h.select { |_, v| v.present? }
    end

    def report_end_date
      @report.end_date
    end

    # Override LengthOfStays implementation to use pre-computed context
    def appropriate_move_in_date(_enrollment)
      @ctx.inherited_move_in_date
    end
  end
end
