###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport
  class UniverseCalculator
    include ArelHelper
    include Filter::FilterScopes

    def initialize(filter)
      @filter = filter
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
          next if enrollment.blank? || enrollment.enrollment.blank?

          age = enrollment.client.age_on([@filter.start_date, enrollment.first_date_in_program].max)
          enrollment_cls = enrollment.enrollment.current_living_situations.detect { |cls| cls.InformationDate == enrollment.first_date_in_program }
          education_status = enrollment.enrollment.youth_education_statuses.max_by(&:InformationDate)
          health_and_dv = enrollment.enrollment.health_and_dvs.max_by(&:InformationDate)

          clients[client] = ::MaYyaReport::Client.new(
            client_id: client_id,
            service_history_enrollment_id: enrollment.id,
            entry_date: enrollment.first_date_in_program,
            referral_source: enrollment.enrollment.ReferralSource,
            currently_homeless: currently_homeless?(enrollment_cls),
            at_risk_of_homelessness: at_risk_of_homelessness?(enrollment_cls),
            initial_contact: initial_contact(enrollments_by_client_id[client_id]),
            direct_assistance: direct_assistance?(enrollments_by_client_id[client_id]),
            education_status_date: education_status&.InformationDate,
            current_school_attendance: education_status&.CurrentSchoolAttend,
            current_educational_status: education_status&.CurrentEdStatus,
            age: age,
            gender: gender(enrollment.client),
            race: race(enrollment.client),
            ethnicity: ethnicity(enrollment.client),
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
            rehoused_on: rehoused_on(enrollment.enrollment),
            subsequent_current_living_situations: subsequent_current_living_situations(enrollment.enrollment),
            zip_codes: zip_codes(client),
            flex_funds: flex_funds(enrollments_by_client_id[client_id]),
            language: language(enrollment.enrollment),
          )
        end
      end
    end

    private def client_scope
      ::GrdaWarehouse::Hud::Client.
        distinct.
        joins(:service_history_enrollments).
        merge(enrollment_scope)
    end

    private def clients_with_enrollments(batch)
      enrollment_scope_with_preloads.
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def enrollment_scope
      scope = ::GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @filter.start_date, end_date: @filter.end_date)

      scope = filter_for_projects(scope)
      filter_for_age(scope)
    end

    private def enrollment_scope_with_preloads
      enrollment_scope.
        preload(
          client: [:custom_client_addresses],
          enrollment: [:client, :current_living_situations, :events, :youth_education_statuses, :disabilities, :health_and_dvs, :income_benefits_at_entry, custom_services: [:custom_data_elements]],
          household_enrollments: [:client, :exit],
        )
    end

    private def currently_homeless?(cls)
      cls.present? && cls.CurrentLivingSituation.in?([101, 302, 116])
    end

    private def at_risk_of_homelessness?(cls)
      ! currently_homeless?(cls)
    end

    private def initial_contact(enrollments)
      enrollment = enrollments.last
      enrollment.enrollment.ReferralSource.in?([1, 2, 11, 18, 28, 30, 34, 45, 37, 38, 39]) &&
        enrollments[0...-1].detect { |en| en.first_date_in_program >= @filter.start_date - 24.months }.blank?
    end

    # True if client was referred to flex funds OR if they received flex funds
    private def direct_assistance?(enrollments)
      # CE Event 16 = Referral to emergency assistance/flex fund/furniture assistance
      referred_to_direct_assistance = enrollments.any? do |enrollment|
        enrollment.enrollment.events.any? do |event|
          event.EventDate.between?(@filter.start_date, @filter.end_date) && event.Event == 16
        end
      end

      referred_to_direct_assistance || enrollments.any? { |en| flex_funds_services_in_range(en).any? }
    end

    private def gender(client)
      genders = client.gender_multi
      return 0 if genders == [0]
      return 1 if genders == [1]
      # No guidance on 2 or 3 CulturallySpecific, DifferentIdentity
      return 5 if genders.include?(5) # Transgender (return first because client gets grouped as LGBTQ if present)
      return 4 if genders.include?(4) # Non-Binary
      # Group the following
      return 6 if genders.include?(6) # Questioning
      return 6 if genders.include?(8) # Doesn't know
      return 6 if genders.include?(9) # Prefers not to answer

      return client.GenderNone
    end

    private def race(client)
      return client.RaceNone if client.RaceNone.in?([8, 9, 99])

      race_fields = client.race_fields.excluding(6) # Exclude HispanicLatinaeo from race value
      return 99 if race_fields.size.zero?
      return 10 if race_fields.size > 1 # Multi-racial

      return race_code[*race_fields]
    end

    private def race_code
      HudUtility2024.race_id_to_field_name.excluding(8, 9, 99).invert.stringify_keys
    end

    private def ethnicity(client)
      client.HispanicLatinaeo
    end

    private def disability?(enrollment, disability_type, disability_responses = [1])
      # Find most recent disability record associated with the enrollment for the appropriate type with a value
      # recorded before the end of the reporting period
      disability = enrollment.disabilities.order(InformationDate: :desc).
        detect do |d|
          d.InformationDate < @filter.end_date &&
          d.DisabilityType == disability_type &&
          d.DisabilityResponse.in?([0, 1, 2, 3]) # Include 'no' responses in the sort
        end
      disability.present? && disability.indefinite_and_impairs? && disability.DisabilityResponse.in?(disability_responses)
    end

    private def household_ages(enrollment)
      enrollment.household_enrollments.map do |en|
        next if en.EntryDate > @filter.end_date
        next if en.exit.present? && en.exit.ExitDate < @filter.start_date

        en.client.age_on([@filter.start_date, en.EntryDate].max)
      end.compact
    end

    private def rehoused_on(enrollment)
      enrollment.current_living_situations.
        detect do |cls|
          cls.CurrentLivingSituation.in?([435, 410, 421, 411]) &&
          cls.InformationDate > enrollment.EntryDate
        end&.InformationDate
    end

    private def subsequent_current_living_situations(enrollment)
      enrollment.current_living_situations.
        select do |cls|
        cls.InformationDate.between?(@filter.start_date, @filter.end_date) &&
          cls.InformationDate >= enrollment.EntryDate + 90.days
      end.
        map(&:CurrentLivingSituation)
    end

    # Most recent Zip for each source client
    private def zip_codes(client)
      client.source_clients.map do |source_client|
        source_client.custom_client_addresses.sort_by(&:DateUpdated).map(&:postal_code).compact.last
      end.compact.uniq
    end

    # All flex funds received by all source clients (e.g. ["Transportation", "Child care", "Move-in"])
    # NOTE: Assumes that there is only 1 HMIS data source
    private def flex_funds(enrollments)
      return [] unless flex_funds_service_type && flex_funds_types_cded

      enrollments.map do |enrollment|
        flex_funds_services_in_range(enrollment).map do |service|
          service.custom_data_elements.
            filter { |cde| cde.data_element_definition_id == flex_funds_types_cded.id }.
            map(&:value_string).
            map { |ff_type| ff_type.gsub(/\([^()]*\)/, '').strip } # Remove parenthesized text from label
        end
      end.flatten(2).uniq
    end

    # Valid options are [nil, "English", "Spanish", "Other"]
    private def language(enrollment)
      if enrollment.translation_needed&.zero?
        'English' # If 'No' to translation needed, infer English as primary language (not quite right, but agreed-upon logic)
      elsif enrollment.preferred_language == 367 # Spanish
        'Spanish'
      elsif enrollment.preferred_language.present?
        'Other'
      end
    end

    private def flex_funds_service_type
      @flex_funds_service_type ||= Hmis::Hud::CustomServiceType.find_by(name: 'Flex Funds')
    end

    # Custom data element definition for specifying the type of flex fund received (Eg "rent")
    private def flex_funds_types_cded
      @flex_funds_types_cded ||= Hmis::Hud::CustomDataElementDefinition.find_by(key: :flex_funds_types)
    end

    private def flex_funds_services_in_range(enrollment)
      enrollment.enrollment.custom_services.filter do |service|
        service.custom_service_type_id == flex_funds_service_type.id &&
          service.within_range?(@filter.start_date..@filter.end_date)
      end
    end
  end
end
