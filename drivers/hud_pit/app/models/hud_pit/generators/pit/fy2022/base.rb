###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::Veterans

    private def universe
      add unless populated?

      @universe ||= @report.universe(self.class.question_number)
    end

    private def add
      @generator.client_scope.find_in_batches(batch_size: 1_000) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)

        # Pre-calculate some values
        household_types = {}
        enrollments_by_client_id.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = get_hh_id(last_service_history_enrollment)
          household_types[hh_id] = household_makeup(hh_id, @generator.filter.on)
        end

        pending_associations = {}
        processed_source_clients = Set.new
        # Re-shape client to PIT Client shape
        batch.each do |client|
          # Fetch enrollments for destination client
          enrollments = enrollments_by_client_id[client.id]
          next unless enrollments.present?

          last_service_history_enrollment = enrollments.last
          enrollment = last_service_history_enrollment.enrollment
          source_client = enrollment.client
          next unless source_client

          disabilities = enrollment.disabilities.select { |disability| [1, 2, 3].include?(disability.DisabilityResponse) }
          max_disability_date = disabilities.select { |d| d.InformationDate <= @generator.filter.on }.
            map(&:InformationDate).max
          disabilities_latest = disabilities.select { |d| d.InformationDate == max_disability_date }

          health_and_dv = enrollment.health_and_dvs.
            select { |h| h.InformationDate <= @generator.filter.on && !h.DomesticViolenceVictim.nil? }.
            max_by(&:InformationDate)

          if processed_source_clients.include?(source_client.id)
            @notifier.ping "Duplicate source client: #{source_client.id} for destination client: #{client.id} in enrollment: #{enrollment.id}" if @send_notifications
            next
          end

          age = source_client.age_on(@generator.filter.on)
          hh_id = get_hh_id(last_service_history_enrollment)
          household_ages = ages_for(hh_id, @generator.filter.on)
          household_type = household_types[hh_id]
          # https://files.hudexchange.info/resources/documents/Reporting-Gender-for-the-PIT-Count.pdf
          binary_gender_code = source_client.gender_binary
          binary_gender_code = 4 if binary_gender_code == 6
          pit_gender = HUD.gender(binary_gender_code)
          # Only count clients once (where one category is Multiple Races)
          pit_race = source_client.pit_race
          processed_source_clients << source_client.id
          hoh_veteran = household_member_data(last_service_history_enrollment).detect do |_, member|
            next unless member

            member.veteran_status == 1 && member.relationship_to_hoh == 1
          end.present?

          options = {
            client_id: source_client.id,
            destination_client_id: last_service_history_enrollment.client_id,
            data_source_id: source_client.data_source_id,
            report_instance_id: @report.id,

            age: age,
            dob: source_client.DOB,
            household_type: household_type,
            max_age: household_ages.compact&.max,
            hoh_veteran: hoh_veteran,
            relationship_to_hoh: enrollment.RelationshipToHoH,
            pit_gender: pit_gender,
            female: source_client.Female,
            male: source_client.Male,
            no_single_gender: source_client.NoSingleGender,
            transgender: source_client.Transgender,
            questioning: source_client.Questioning,
            gender_none: source_client.GenderNone,
            pit_race: pit_race,
            am_ind_ak_native: source_client.AmIndAKNative,
            asian: source_client.Asian,
            black_af_american: source_client.BlackAfAmerican,
            native_hi_other_pacific: source_client.NativeHIPacific,
            white: source_client.White,
            race_none: source_client.RaceNone,
            ethnicity: source_client.Ethnicity,
            veteran: source_client.VeteranStatus,
            chronically_homeless: enrollment.chronically_homeless_at_start?,
            substance_use: disabilities_latest.detect(&:substance?)&.DisabilityResponse&.present?,
            substance_use_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.substance? }&.DisabilityResponse.present?,
            domestic_violence: health_and_dv&.DomesticViolenceVictim,
            domestic_violence_currently_fleeing: health_and_dv&.CurrentlyFleeing,
            hiv_aids: disabilities_latest.detect(&:hiv?)&.DisabilityResponse&.present?,
            hiv_aids_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.hiv? }&.DisabilityResponse.present?,
            mental_illness: disabilities_latest.detect(&:mental?)&.DisabilityResponse&.present?,
            mental_illness_indefinite_impairing: disabilities_latest.detect { |d| d.indefinite_and_impairs? && d.mental? }&.DisabilityResponse.present?,
            project_type: last_service_history_enrollment.computed_project_type,
            project_name: last_service_history_enrollment.project_name,
            entry_date: last_service_history_enrollment.first_date_in_program,
            exit_date: last_service_history_enrollment.last_date_in_program,
          }
          pending_associations[client] = report_client_universe.new(options)
        end

        # Import PIT clients
        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
          },
        )

        # Attach PIT Clients to relevant questions
        @report.build_for_questions.each do |question_number|
          universe_cell = @report.universe(question_number)
          generator = @generator.class.questions[question_number]
          universe_cell.add_universe_members(generator.filter_pending_associations(pending_associations))
        end
      end
    end

    private def report_client_universe
      HudPit::Fy2022::HicClient
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def enrollment_scope
      preloads = {
        enrollment: [
          :disabilities,
          :project,
          :enrollment_coc_at_entry,
          :health_and_dvs,
          :exit,
        ],
      }
      enrollment_scope_without_preloads.preload(preloads)
    end

    # open enrollments on the date with service that isn't extrapolated
    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        ongoing(on_date: @generator.filter.on).
        with_service_between(start_date: @generator.filter.on, end_date: @generator.filter.on, service_scope: :service_excluding_extrapolated).
        joins(:enrollment)
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    delegate :client_scope, to: :@generator

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

    private def populated?
      @report.report_cells.joins(:universe_members).exists?
    end

    private def a_t
      @a_t ||= HudPit::Fy2022::HicClient.arel_table
    end
  end
end
