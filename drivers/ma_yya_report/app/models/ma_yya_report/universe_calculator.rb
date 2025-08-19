###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
module MaYyaReport
  class UniverseCalculator
    include ArelHelper
    include Filter::FilterScopes
    include Memery

    attr_reader :filter

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
          # For enrollment specific calculations we'll use the most recent enrollment
          # that overlaps the reporting period and universe
          enrollment = enrollments_by_client_id[client_id].last
          next if enrollment.blank? || enrollment.enrollment.blank?

          age = enrollment.client.age_on([filter.start_date, enrollment.first_date_in_program].max)
          enrollment_cls = enrollment.enrollment.current_living_situations.detect { |cls| cls.InformationDate == enrollment.first_date_in_program }
          education_status = enrollment.enrollment.youth_education_statuses.max_by(&:InformationDate)
          employment_status = enrollment.enrollment.employment_educations.max_by(&:InformationDate)
          health_and_dv = enrollment.enrollment.health_and_dvs.max_by(&:InformationDate)

          clients[client] = ::MaYyaReport::Client.new(
            client_id: client_id,
            service_history_enrollment_id: enrollment.id,
            entry_date: enrollment.first_date_in_program,
            referral_source: enrollment.enrollment.ReferralSource,
            currently_homeless: currently_homeless?(enrollment_cls), # on entry date
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
            employed: employment_status&.Employed == 1,
            former_foster_ward: enrollment.enrollment.FormerWardChildWelfare == 1,
            former_juvenile_justice_ward: enrollment.enrollment.FormerWardJuvenileJustice == 1,
            voluntary_dcf_service: enrollment.enrollment.ReferralSource == 30,
            voluntary_dys_yes_service: enrollment.enrollment.ReferralSource == 34,
            exchange_for_sex: enrollment.enrollment.exit&.ExchangeForSex == 1,
            permanent_exit_date: permanent_exit_date(client_id),
            days_to_return: days_to_return(client_id),
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

    # anyone of appropriate age enrolled in the chosen projects during the reporting period
    private def enrollment_scope
      enrollment_scope_without_date_range.
        open_between(start_date: filter.start_date, end_date: filter.end_date)
    end

    private def enrollment_scope_without_date_range
      scope = ::GrdaWarehouse::ServiceHistoryEnrollment.
        entry
      filter.apply_criteria(scope, tags: [:warehouse], except: [:filter_for_range])
    end

    private def enrollment_scope_with_preloads
      enrollment_scope.
        preload(
          client: [:custom_client_addresses],
          enrollment: [:client, :current_living_situations, :events, :youth_education_statuses, :disabilities, :health_and_dvs, :income_benefits_at_entry, custom_services: [:custom_data_elements]],
          household_enrollments: [:client, :exit],
        )
    end

    private def return_lookback_range
      @return_lookback_range ||= filter.start_date - 730.days .. filter.end_date
    end

    # Days to return is the number of days between the most-recent entry into homelessness and the most-recent prior exit to permanent housing
    private def days_to_return(client_id)
      homeless_date = start_of_most_recent_homelessness(client_id)
      permanent_exit_date = permanent_exit_date(client_id)
      return nil unless homeless_date && permanent_exit_date

      (homeless_date - permanent_exit_date).to_i
    end

    memoize private def start_of_most_recent_homelessness(client_id)
      [
        homeless_cls_dates_by_client_id[client_id],
        enrolled_in_homeless_project_scope_by_client_id[client_id],
      ].compact.min
    end

    memoize private def permanent_exit_date(client_id)
      [
        permanent_destinations_by_client_id[client_id],
        permanent_locations_by_client_id[client_id],
      ].compact.max
    end

    # Identifies clients enrolled in homeless projects during the reporting period and memoizes their earliest enrollment date.
    #
    # This method queries the enrollment scope for homeless projects within the specified date range
    # and returns a hash mapping client IDs to their earliest first_date_in_program during the period.
    # If a client has multiple enrollments, only the earliest date is retained.
    #
    # @return [Hash<Integer, Date>] A hash mapping client IDs to their earliest enrollment date in a homeless project
    #         during the reporting period
    memoize private def enrolled_in_homeless_project_scope_by_client_id
      {}.tap do |h|
        enrollment_scope.homeless.
          open_between(start_date: filter.start_date, end_date: filter.end_date).
          pluck(:client_id, :first_date_in_program).
          each do |client_id, first_date_in_program|
            h[client_id] = first_date_in_program if h[client_id].blank? || first_date_in_program < h[client_id]
          end
      end
    end

    # Identifies clients with homeless Current Living Situations (CLS) on the entry date of an enrollment
    # that overlaps the reporting period.
    #
    # It filters for specific homeless situations:
    # - 116: Place not meant for habitation
    # - 101: Emergency shelter
    # - 118: Safe haven
    # - 302: Transitional housing
    # - 336: Staying or living in a friend's room, apartment, or house
    # - 335: Staying or living in a family member's room, apartment, or house
    #
    # @return [Hash<Integer, Date>] A hash mapping client IDs to their earliest homeless CLS date
    memoize private def homeless_cls_dates_by_client_id
      {}.tap do |h|
        ::GrdaWarehouse::Hud::CurrentLivingSituation.
          where(CurrentLivingSituation: [116, 101, 118, 302, 336, 335]).
          joins(enrollment: :service_history_enrollment).
          merge(enrollment_scope).
          select(she_t[:client_id], she_t[:first_date_in_program], :InformationDate).
          each do |client_id, entry_date, information_date|
            next if entry_date != information_date

            h[client_id] = information_date if h[client_id].blank? || information_date < h[client_id]
          end
      end
    end

    # Identifies clients who exited to permanent housing destinations within the 2-year lookback period and memoizes their most recent exit date.
    #
    # This method queries Exit records to find clients who achieved permanent housing outcomes
    # during the lookback period (730 days before the report start date through the report end date).
    # It filters for specific permanent destination codes:
    # - 422: Staying or living with family, permanent tenure
    # - 423: Staying or living with friends, permanent tenure
    # - 410: Rental by client, no ongoing housing subsidy
    # - 435: Rental by client, with ongoing housing subsidy
    # - 421: Owned by client, with ongoing housing subsidy
    # - 411: Owned by client, no ongoing housing subsidy
    #
    # For each client with multiple permanent exits during the period, only the most recent
    # ExitDate is retained to identify when they most recently achieved permanent housing.
    #
    # @return [Hash<Integer, Date>] A hash mapping client IDs to their most recent exit date
    #         to a permanent housing destination within the lookback period
    memoize private def permanent_destinations_by_client_id
      {}.tap do |h|
        ::GrdaWarehouse::Hud::Exit.
          where(ExitDate: return_lookback_range).
          where(Destination: [422, 423, 410, 435, 421, 411]).
          joins(enrollment: :service_history_enrollment).
          merge(enrollment_scope_without_date_range).
          pluck(:client_id, :ExitDate).
          each do |client_id, exit_date|
            homeless_start_date = start_of_most_recent_homelessness(client_id)
            # Ignore any permanent exits that occurred after the start of homelessness.
            # We'll pick those up in next year's report
            next if homeless_start_date && exit_date > homeless_start_date

            h[client_id] = exit_date if h[client_id].blank? || exit_date > h[client_id]
          end
      end
    end

    # Identifies clients who had Current Living Situations (CLS) indicating permanent housing within the 2-year lookback period and memoizes their most recent occurrence date.
    #
    # This method queries Current Living Situation records to find clients who were living in permanent
    # housing during the lookback period (730 days before the report start date through the report end date).
    # It filters for specific permanent housing CLS codes:
    # - 410: Rental by client, no ongoing housing subsidy
    # - 435: Rental by client, with ongoing housing subsidy
    # - 421: Owned by client, with ongoing housing subsidy
    # - 411: Owned by client, no ongoing housing subsidy
    #
    # For each client with multiple permanent housing CLS records during the period, only the most recent
    # InformationDate is retained to identify when they most recently were in permanent housing.
    #
    # This method complements permanent_destinations_by_client_id by capturing housing status through
    # CLS records rather than exit destinations, providing a more comprehensive view of housing stability.
    #
    # @return [Hash<Integer, Date>] A hash mapping client IDs to their most recent CLS date
    #         indicating permanent housing within the lookback period
    memoize private def permanent_locations_by_client_id
      {}.tap do |h|
        ::GrdaWarehouse::Hud::CurrentLivingSituation.
          where(CurrentLivingSituation: [410, 435, 421, 411]).
          where(InformationDate: return_lookback_range).
          joins(enrollment: :service_history_enrollment).
          merge(enrollment_scope_without_date_range).
          pluck(:client_id, :InformationDate).
          each do |client_id, information_date|
            homeless_start_date = start_of_most_recent_homelessness(client_id)
            # Ignore any permanent locations that occurred after the start of homelessness.
            # We'll pick those up in next year's report
            next if homeless_start_date && information_date > homeless_start_date

            h[client_id] = information_date if h[client_id].blank? || information_date > h[client_id]
          end
      end
    end
    private def currently_homeless?(cls)
      cls.present? && cls.CurrentLivingSituation.in?([116, 101, 118, 302, 336, 335])
    end

    private def at_risk_of_homelessness?(cls)
      cls.present? && ! cls.CurrentLivingSituation.in?([116, 101, 118, 302, 336, 335])
    end

    private def initial_contact(enrollments)
      enrollment = enrollments.last
      enrollment.enrollment.ReferralSource.in?([1, 2, 11, 18, 28, 30, 34, 45, 37, 38, 39]) &&
        enrollments[0...-1].detect { |en| en.first_date_in_program >= filter.start_date - 24.months }.blank?
    end

    # True if client was referred to flex funds OR if they received flex funds
    private def direct_assistance?(enrollments)
      # CE Event 16 = Referral to emergency assistance/flex fund/furniture assistance
      referred_to_direct_assistance = enrollments.any? do |enrollment|
        enrollment.enrollment.events.any? do |event|
          event.EventDate.between?(filter.start_date, filter.end_date) && event.Event == 16
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
      return 99 if race_fields.empty?
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
          d.InformationDate < filter.end_date &&
          d.DisabilityType == disability_type &&
          d.DisabilityResponse.in?([0, 1, 2, 3]) # Include 'no' responses in the sort
        end
      disability.present? && disability.indefinite_and_impairs? && disability.DisabilityResponse.in?(disability_responses)
    end

    private def household_ages(enrollment)
      enrollment.household_enrollments.map do |en|
        next if en.EntryDate > filter.end_date
        next if en.exit.present? && en.exit.ExitDate < filter.start_date

        en.client.age_on([filter.start_date, en.EntryDate].max)
      end.compact
    end

    # The earliest CLS indicating the client was housed that occurred after
    # the entry date into the enrollment
    private def rehoused_on(enrollment)
      enrollment.current_living_situations.
        order(InformationDate: :asc).
        detect do |cls|
          cls.CurrentLivingSituation.in?([435, 410, 421, 411]) &&
          cls.InformationDate > enrollment.EntryDate
        end&.InformationDate
    end

    # The CLSs occurring within the report range
    # and at least 90 days after entry
    private def subsequent_current_living_situations(enrollment)
      enrollment.current_living_situations.
        order(InformationDate: :asc).
        select do |cls|
        cls.InformationDate.between?(filter.start_date, filter.end_date) &&
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
          service.within_range?(filter.start_date..filter.end_date)
      end
    end
  end
end
