###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Resolves PSDE field values for destination clients in batch.
  class PsdeValueResolver
    include Hmis::Concerns::HmisArelHelper

    # HUD DisabilityType codes, keyed by the names used across the warehouse (:physical, :substance, etc.)
    DISABILITY_TYPE_CODES = GrdaWarehouse::Hud::Disability.disability_types.invert.freeze

    # Maps NoYes-disability field keys to their HUD DisabilityType code. Substance use is deliberately
    # excluded here — it is dispatched separately in boolean_field_source because it has additional "yes" response codes.
    NO_YES_DISABILITY_TYPES = {
      PsdeFieldRegistry::PHYSICAL_DISABILITY.key => DISABILITY_TYPE_CODES.fetch(:physical),
      PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY.key => DISABILITY_TYPE_CODES.fetch(:developmental),
      PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION.key => DISABILITY_TYPE_CODES.fetch(:chronic),
      PsdeFieldRegistry::HIV_AIDS.key => DISABILITY_TYPE_CODES.fetch(:hiv),
      PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.key => DISABILITY_TYPE_CODES.fetch(:mental),
    }.freeze

    SUBSTANCE_USE_DISABILITY_TYPE = DISABILITY_TYPE_CODES.fetch(:substance)

    # Meaningful raw HUD response codes from NoYesReasonsForMissingData.
    # Anything else — 8/9/99/nil — is skipped as "not meaningful".
    NO_YES_RESPONSES = [0, 1].freeze
    SUBSTANCE_USE_EXTRA_YES_RESPONSE_CODES = [2, 3].freeze # 1=Alcohol, 2=Drug, 3=Both; all collapse to true

    # Disability responses considered by the disabling condition inference, matching the warehouse
    # (GrdaWarehouse::Hud::Client.disabled_client_because_disability_scope). Codes 2/3 are only valid for
    # substance use, but the warehouse accepts them for every type, so we do too.
    DISABILITY_YES_RESPONSE_CODES = GrdaWarehouse::Hud::Disability.positive_responses
    DISABILITY_NO_RESPONSE_CODE = 0
    DISABILITY_RESPONSE_CODES = [DISABILITY_NO_RESPONSE_CODE, *DISABILITY_YES_RESPONSE_CODES].freeze

    # HUD Disabling Condition qualify test for a disability row, mirroring
    # GrdaWarehouse::Hud::Disability#indefinite_and_impairs?: a Yes response qualifies when the type is
    # Developmental or HIV/AIDS, or when Dependent Field A (IndefiniteAndImpairs) is Yes.
    ALWAYS_QUALIFYING_DISABILITY_TYPES = DISABILITY_TYPE_CODES.values_at(:developmental, :hiv).freeze
    INDEFINITE_AND_IMPAIRS_YES = 1

    # A Disabilities row plucked for the disabling condition inference
    DisabilityRow = Data.define(:client_id, :type, :response, :indefinite_and_impairs, :information_date)

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # Resolves the value for a PSDE field for a given set of destination clients.
    def call(clients, field)
      case field.key
      when PsdeFieldRegistry::TOTAL_MONTHLY_INCOME.key
        resolve_total_monthly_income(clients)
      when PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.key))
      when PsdeFieldRegistry::MENTAL_HEALTH_DISORDER_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.key))
      when PsdeFieldRegistry::SUBSTANCE_USE_DISORDER.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::SUBSTANCE_USE_DISORDER.key))
      when PsdeFieldRegistry::SUBSTANCE_USE_DISORDER_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::SUBSTANCE_USE_DISORDER.key))
      when PsdeFieldRegistry::PHYSICAL_DISABILITY.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::PHYSICAL_DISABILITY.key))
      when PsdeFieldRegistry::PHYSICAL_DISABILITY_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::PHYSICAL_DISABILITY.key))
      when PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY.key))
      when PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY.key))
      when PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION.key))
      when PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION.key))
      when PsdeFieldRegistry::HIV_AIDS.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::HIV_AIDS.key))
      when PsdeFieldRegistry::HIV_AIDS_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::HIV_AIDS.key))
      when PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR.key
        resolve_latest_boolean_response(clients, **boolean_field_source(PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR.key))
      when PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR_VALUES_IN_WINDOW.key
        resolve_boolean_values_in_window(clients, **boolean_field_source(PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR.key))
      when PsdeFieldRegistry::DISABLING_CONDITION.key
        resolve_disabling_condition(
          clients,
          disability_row_answered: method(:hud_disabling_condition_row_answered?),
          disability_row_qualifies: method(:hud_disabling_condition_row?),
        )
      when PsdeFieldRegistry::ANY_REPORTED_DISABILITY.key
        resolve_disabling_condition(
          clients,
          disability_row_answered: method(:disability_response_answered?),
          disability_row_qualifies: method(:disability_yes_row?),
        )
      else
        raise ArgumentError, "Unknown PSDE field \"#{field.key}\""
      end
    end

    private

    # Unlike CAS +max_current_total_monthly_income+, which takes the max across open enrollments,
    # this resolver selects the single latest valid IncomeBenefits row across all scoped enrollments.
    # (Ignoring 8/9/99/nil responses to IncomeFromAnySource.)
    #
    # @return [Hash{Integer => Numeric, nil}]
    def resolve_total_monthly_income(clients)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no valid IncomeBenefits rows will have a nil value.
      result = client_ids.index_with { nil }

      rows = scoped_rows(client_ids, Hmis::Hud::IncomeBenefit.all).pluck(
        wc_t[:destination_id],
        ib_t[:IncomeFromAnySource],
        ib_t[:TotalMonthlyIncome],
      )

      rows.group_by(&:first).each do |client_id, client_rows|
        selected = client_rows.find { |row| valid_total_monthly_income_row?(income_from_any_source: row[1], total_monthly_income: row[2]) }
        next unless selected

        income_from_any_source = selected[1]
        total_monthly_income = selected[2]
        total_monthly_income = 0 if income_from_any_source.zero? # "No Income From Any Source" = $0 income

        result[client_id] = total_monthly_income
      end

      result
    end

    # Infers disabling condition with the same algorithm the warehouse uses for CAS
    # (GrdaWarehouse::Hud::Client.disabled_client_scope), but only over enrollments in the CE eligibility scope.
    # A client is disabled if either rule says Yes:
    #   A) the latest in-scope enrollment with a Yes/No DisablingCondition says Yes, or
    #   B) any disability type has a qualifying row on its latest in-scope InformationDate.
    #
    # The two row tests are the only things that differ between fields:
    # * +disability_row_answered+ decides whether a row is an answer that can be the latest for its type.
    # * +disability_row_qualifies+ decides whether that row counts (any Yes, or a Yes that meets HUD's
    #   Disabling Condition definition).
    #
    # Returns true if A or B is Yes; false if either rule had a meaningful answer; nil if neither did.
    #
    # @param disability_row_answered [#call] takes a DisabilityRow, returns Boolean
    # @param disability_row_qualifies [#call] takes a DisabilityRow, returns Boolean
    # @return [Hash{Integer => Boolean, nil}]
    def resolve_disabling_condition(clients, disability_row_answered:, disability_row_qualifies:)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      enrollment_flags = disabling_condition_by_client(client_ids)
      disability_flags = disabled_because_disability_by_client(
        client_ids,
        disability_row_answered: disability_row_answered,
        disability_row_qualifies: disability_row_qualifies,
      )

      client_ids.index_with do |client_id|
        rule_a = enrollment_flags[client_id]
        rule_b = disability_flags[client_id]

        if rule_a || rule_b
          true
        elsif rule_a == false || rule_b == false
          false
        end
      end
    end

    # Rule A. Warehouse counterpart: GrdaWarehouse::Hud::Client.disabling_condition_client_scope.
    # Picks the latest in-scope enrollment with a Yes/No DisablingCondition per client. Unlike the warehouse,
    # ties on EntryDate are broken deterministically, and WIP enrollments are included.
    #
    # @return [Hash{Integer => Boolean}] clients without a Yes/No answer are absent
    def disabling_condition_by_client(client_ids)
      ordering = [
        e_t[:EntryDate].desc.nulls_last,
        e_t[:DateUpdated].desc.nulls_last,
        e_t[:id].desc,
      ]
      rows = eligibility_scope.call(client_ids).
        where(e_t[:DisablingCondition].in(NO_YES_RESPONSES)).
        order(*ordering).
        pluck(wc_t[:destination_id], e_t[:DisablingCondition])

      latest_row_by_client = rows.group_by(&:first).transform_values(&:first)
      latest_row_by_client.transform_values { |(_client_id, response)| response_to_boolean(response) }
    end

    # Rule B. Warehouse counterpart: GrdaWarehouse::Hud::Client.disabled_client_because_disability_scope.
    # Rows with a response of 0-3 that pass +disability_row_answered+ are candidates for "latest". For each
    # disability type, the type is positive if any row on its latest InformationDate passes
    # +disability_row_qualifies+ (so a same-day qualifying row wins, as in the warehouse). A later answered row
    # replaces an earlier qualifying row of the same type even if the later row does not qualify. Rows without
    # an InformationDate are skipped.
    #
    # @return [Hash{Integer => Boolean}] clients without any answered disability row are absent
    def disabled_because_disability_by_client(client_ids, disability_row_answered:, disability_row_qualifies:)
      disability_scope = Hmis::Hud::Disability.
        where(
          DisabilityType: DISABILITY_TYPE_CODES.values,
          DisabilityResponse: DISABILITY_RESPONSE_CODES,
        ).
        where.not(InformationDate: nil)

      # Ordering is unused here: rows are grouped and the latest date per type is picked below.
      unordered_rows = scoped_rows(client_ids, disability_scope).reorder(nil)
      plucked_rows = unordered_rows.pluck(
        wc_t[:destination_id],
        d_t[:DisabilityType],
        d_t[:DisabilityResponse],
        d_t[:IndefiniteAndImpairs],
        d_t[:InformationDate],
      )
      all_rows = plucked_rows.map { |values| DisabilityRow.new(*values) }
      answered_rows = all_rows.select { |row| disability_row_answered.call(row) }

      rows_by_client = answered_rows.group_by(&:client_id)
      rows_by_client.transform_values do |client_rows|
        rows_by_type = client_rows.group_by(&:type)
        rows_by_type.values.any? do |type_rows|
          latest_disability_rows_qualify?(type_rows, disability_row_qualifies: disability_row_qualifies)
        end
      end
    end

    # True if any row on the latest InformationDate in +type_rows+ passes +disability_row_qualifies+.
    def latest_disability_rows_qualify?(type_rows, disability_row_qualifies:)
      latest_date = type_rows.map(&:information_date).max
      latest_rows = type_rows.select { |row| row.information_date == latest_date }
      latest_rows.any? { |row| disability_row_qualifies.call(row) }
    end

    # Answered test for psde.any_reported_disability: any No or Yes response, as in the warehouse.
    def disability_response_answered?(row)
      row.response.in?(DISABILITY_RESPONSE_CODES)
    end

    # Row test for psde.any_reported_disability: any Yes response, whether or not it is long-term or impairing.
    def disability_yes_row?(row)
      row.response.in?(DISABILITY_YES_RESPONSE_CODES)
    end

    # Answered test for psde.disabling_condition (HUD definition). A Yes on a type that needs the
    # IndefiniteAndImpairs follow-up is only an answer when that follow-up is No or Yes. Leaving the follow-up
    # blank (or 8/9/99) is missing data, so it does not replace an earlier qualifying row of the same type.
    def hud_disabling_condition_row_answered?(row)
      return false unless disability_response_answered?(row)
      return true unless disability_yes_row?(row)
      return true if row.type.in?(ALWAYS_QUALIFYING_DISABILITY_TYPES)

      row.indefinite_and_impairs.in?(NO_YES_RESPONSES)
    end

    # Row test for psde.disabling_condition (HUD definition).
    # Reference: GrdaWarehouse::Hud::Disability#indefinite_and_impairs?
    def hud_disabling_condition_row?(row)
      return false unless disability_yes_row?(row)
      return true if row.type.in?(ALWAYS_QUALIFYING_DISABILITY_TYPES)

      row.indefinite_and_impairs == INDEFINITE_AND_IMPAIRS_YES
    end

    # Describes where a boolean PSDE field's response lives in HUD data, keyed by its base
    # (suffix-stripped) key. Returns { scope:, column:, extra_yes_response_codes: } which both the
    # "latest" and "all enrollment" resolvers splat straight into their keyword args.
    def boolean_field_source(base_key)
      case base_key
      when PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR.key
        { scope: Hmis::Hud::HealthAndDv.all, column: hdv_t[:DomesticViolenceSurvivor] }
      when PsdeFieldRegistry::SUBSTANCE_USE_DISORDER.key
        # Substance use collapses Alcohol/Drug/Both (1/2/3) to true, No (0) to false.
        {
          scope: disability_scope(SUBSTANCE_USE_DISABILITY_TYPE),
          column: d_t[:DisabilityResponse],
          extra_yes_response_codes: SUBSTANCE_USE_EXTRA_YES_RESPONSE_CODES,
        }
      when *NO_YES_DISABILITY_TYPES.keys
        { scope: disability_scope(NO_YES_DISABILITY_TYPES.fetch(base_key)), column: d_t[:DisabilityResponse] }
      else
        raise ArgumentError, "Unknown boolean PSDE field \"#{base_key}\""
      end
    end

    # Picks the single latest row with a Yes/No response per client and converts it to a boolean.
    # Returns nil when no row has a Yes/No response in scope.
    #
    # extra_yes_response_codes: an array of response codes that should be treated as "yes" responses.
    #   This is used for Substance Use Disorder, where Alcohol/Drug/Both (1/2/3) are all Yes responses.
    #
    # @return [Hash{Integer => Boolean, nil}]
    def resolve_latest_boolean_response(clients, scope:, column:, extra_yes_response_codes: [])
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no Yes/No responses will have a nil value.
      result = client_ids.index_with { nil }
      rows = scoped_rows(client_ids, scope).pluck(wc_t[:destination_id], column)
      rows.group_by(&:first).each do |client_id, client_rows|
        client_rows.each do |row|
          value = response_to_boolean(row.last, extra_yes_response_codes: extra_yes_response_codes)
          next if value.nil?

          result[client_id] = value
          break
        end
      end
      result
    end

    # Collects every meaningful Yes/No response recorded within the configured eligibility scope
    # (lookback window + optional project group) and converts each to a boolean.
    # Clients with no Yes/No responses get []. Shape: Hash{Integer => Array<Boolean>}.
    def resolve_boolean_values_in_window(clients, scope:, column:, extra_yes_response_codes: [])
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no Yes/No rows will have an empty array.
      result = client_ids.index_with { [] }

      # scoped_rows already orders rows newest-first
      rows = scoped_rows(client_ids, scope).pluck(wc_t[:destination_id], column)
      rows.group_by(&:first).each do |client_id, client_rows|
        result[client_id] = client_rows.map(&:last).
          map { |code| response_to_boolean(code, extra_yes_response_codes: extra_yes_response_codes) }.
          compact. # drop nils
          uniq # deduplicate, keeping the newest occurrence of each value
      end
      result
    end

    # Scoped, ordered relation for a HUD table restricted to eligible enrollments.
    # Ordered so the first row is the most recent.
    # Callers pluck the specific columns they need.
    def scoped_rows(client_ids, scope)
      scope.
        joins(:enrollment).
        merge(eligibility_scope.call(client_ids)).
        order(information_date: :desc, date_updated: :desc, id: :desc)
    end

    # HUD NoYes code -> boolean.
    # Supports additional "yes" response codes for Substance Use Disorder (1/2/3)
    def response_to_boolean(code, extra_yes_response_codes: [])
      case code
      when 0 then false
      when 1 then true
      when *extra_yes_response_codes then true
      end
    end

    def disability_scope(disability_type)
      Hmis::Hud::Disability.where(d_t[:DisabilityType].eq(disability_type))
    end

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end

    # Used to evaluate HUD 1.7 NoYesReasonsForMissingData response code (0/1/8/9/99/nil)
    # Returns true if the response is meaningful (0/1)
    def meaningful_yes_no_response?(value)
      value.in?(NO_YES_RESPONSES)
    end

    # Yes (1) with a blank MonthlyTotalIncome is invalid data and is skipped, same as 8/9/99/nil on IncomeFromAnySource.
    def valid_total_monthly_income_row?(income_from_any_source:, total_monthly_income:)
      # 8/9/99/nil on IncomeFromAnySource = skip
      return false unless meaningful_yes_no_response?(income_from_any_source)
      # 1(Yes) on IncomeFromAnySource with no MonthlyTotalIncome = skip, invalid
      return false if income_from_any_source == 1 && total_monthly_income.nil?

      true
    end

    def extract_client_ids(clients)
      case clients
      when ActiveRecord::Relation
        clients.pluck(:id)
      else
        Array(clients).map(&:id)
      end
    end
  end
end
