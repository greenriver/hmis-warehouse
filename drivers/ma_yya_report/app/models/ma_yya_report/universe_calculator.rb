###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport
  class UniverseCalculator
    include Filter::FilterScopes

    def initialize(filter)
      @filter = filter
    end

    def client_ids
      # We don't use tap here to allow for '+='
      client_ids = Set.new
      client_scope.find_in_batches do |batch|
        clients = for_batch(batch)
        client_ids += clients.keys
      end
      client_ids
    end

    def calculate(&post_processor)
      client_scope.find_in_batches do |batch|
        post_processor.call(for_batch(batch))
      end
    end

    private def for_batch(batch)
      enrollments_by_client_id = clients_with_enrollments(batch)
      {}.tap do |clients|
        batch.each do |client|
          client_id = client.id
          enrollment = enrollments_by_client_id[client_id].last
          enrollment_cls = enrollment.enrollment.current_living_situations.detect { |cls| cls.InformationDate == enrollment.first_date_in_program }
          education_status = enrollment.enrollment.youth_education_statuses.max_by(&:InformationDate)
          health_and_dv = enrollment.enrollment.health_and_dvs.max_by(&:InformationDate)

          clients[client_id] = {
            client_id: client_id,
            service_history_enrollment_id: enrollment.id,
            entry_date: enrollment.first_date_in_program,
            referral_source: enrollment.enrollment.ReferralSource,
            currently_homeless: currently_homeless?(enrollment_cls),
            at_risk_of_homelessness: at_risk_of_homelessness?(enrollment_cls),
            initial_contact: initial_contact(enrollments_by_client_id[client_id]),
            direct_assistance: direct_assistance?(enrollment.enrollment),
            current_school_attendance: education_status&.CurrentSchoolAttend,
            current_educational_status: education_status&.CurrentEdStatus,
            age: enrollment.client.age_on([@filter.start_date, enrollment.first_date_in_program].max),
            gender: gender(enrollment.client),
            race: race(enrollment.client),
            ethnicity: enrollment.client.Ethnicity,
            mental_health_disorder: disability?(enrollment.enrollment, 9),
            substance_use_disorder: disability?(enrollment.enrollment, 10, [1, 2, 3]),
            physical_disability: disability?(enrollment.enrollment, 5) || disability?(enrollment.enrollment, 7),
            developmental_disability: disability?(enrollment.enrollment, 6),
            pregnant: health_and_dv&.PregnancyStatus,
            due_date: health_and_dv&.DueDate,
            head_of_household: enrollment.head_of_household?,
            household_ages: household_ages(enrollment),
            sexual_orientation: enrollment.enrollment.SexualOrientation,
            most_recent_education_status: education_status&.MostRecentEdStatus,
            health_insurance: enrollment.enrollment.income_benefits_at_entry&.InsuranceFromAnySource == 1,
            subsequent_current_living_situations: subsequent_current_living_situations(enrollment.enrollment),
          }
        end
      end
    end

    private def client_scope
      enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.open_between(start_date: @filter.start_date, end_date: @filter.end_date)
      enrollment_scope = filter_for_projects(enrollment_scope)

      GrdaWarehouse::Hud::Client.
        distinct.
        joins(:service_history_enrollments).
        merge(enrollment_scope)
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        preload(
          :client,
          enrollment: [:client, :current_living_situations, :events, :youth_education_statuses, :disabilities, :health_and_dvs, :income_benefits_at_entry],
          household_enrollments: [:client, :exit],
        ).
        open_between(start_date: @filter.start_date, end_date: @filter.end_date)

      filter_for_projects(scope)
    end

    private def currently_homeless?(cls)
      cls.present? && cls.CurrentLivingSituation.in?([1, 2, 16])
    end

    private def at_risk_of_homelessness?(cls)
      ! currently_homeless?(cls)
      # cls.present? &&
      #   cls.CurrentLivingSituation.in?(15, 6, 7, 25, 4, 5, 29, 14, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11) &&
      #   cls.LeaveSituation14Days == 1 &&
      #   cls.SubsequentResidence.in?([0, 8]) &&
      #   cls.ResourcesToObtain.in?([0, 8])
    end

    private def initial_contact(enrollments)
      enrollment = enrollments.last
      enrollment.enrollment.ReferralSource.in?([1, 2, 11, 18, 28, 30, 34, 45, 37, 38, 39]) &&
        enrollments[0...-1].detect { |en| en.first_date_in_program >= @filter.start_date - 24.months }.blank?
    end

    private def direct_assistance?(enrollment)
      enrollment.
        events.
        select { |event| event.EventDate.between?(@filter.start_date, @filter.end_date) }.
        any? { |event| event.Event == 16 }
    end

    private def gender(client)
      genders = client.gender_multi
      return 0 if genders == [0]
      return 1 if genders == [1]
      return 6 if genders.include?(6)
      return 4 if genders.include?(4) || genders == [0, 1] || genders == [0, 1, 5]
      return 5 if genders == [0, 5] || genders == [1, 5] || genders == [5] # rubocop:disable Style/MultipleComparison

      return client.GenderNone
    end

    private def race(client)
      return client.RaceNone if client.RaceNone.in?([8, 9, 99])

      race_fields = client.race_fields
      return 99 if race_fields.size.zero?
      return 6 if race_fields.size > 1

      return race_code[*race_fields]
    end

    private def race_code
      {
        'AmIndAKNative' => 1,
        'Asian' => 2,
        'BlackAfAmerican' => 3,
        'NativeHIOtherPacific' => 4,
        'White' => 5,
      }.freeze
    end

    private def disability?(enrollment, disability_type, disability_responses = [1])
      # Find most recent disability record associated with the enrollment for the appropriate type with a value
      # recorded before the end of the reporting period
      disability = enrollment.disabilities.detect do |d|
        d.InformationDate < @filter.end_date &&
          d.DisabilityType == disability_type &&
          d.DisabilityResponse.in?([0, 1, 2, 3])
      end
      disability.present? && disability.IndefiniteAndImpairs == 1 && disability.DisabilityResponse.in?(disability_responses)
    end

    private def household_ages(enrollment)
      enrollment.household_enrollments.map do |en|
        next if en.EntryDate > @filter.end_date
        next if en.exit.present? && en.exit.ExitDate < @filter.start_date

        en.client.age_on([@filter.start_date, en.EntryDate].max)
      end.compact
    end

    private def subsequent_current_living_situations(enrollment)
      enrollment.current_living_situations.
        select do |cls|
        cls.InformationDate.between?(@filter.start_date, @filter.end_date) &&
          cls.InformationDate >= enrollment.EntryDate + 90.days
      end.
        map(&:CurrentLivingSituation)
    end
  end
end
