###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Infers disabling condition for destination clients in batch, backing psde.disabling_condition and
  # psde.any_reported_disability.
  #
  # Uses the same algorithm the warehouse uses for CAS (GrdaWarehouse::Hud::Client.disabled_client_scope), but only
  # over enrollments in the CE eligibility scope. It ports the algorithm instead of calling the warehouse scopes because
  # those can't apply the lookback window or project group, and the warehouse's enrollment-flag rule depends on
  # service history, which lags new HMIS enrollments. A client is disabled if either rule says Yes:
  #   A) the latest in-scope enrollment with a Yes/No DisablingCondition says Yes, or
  #   B) any disability type has a qualifying row on its latest in-scope InformationDate.
  #
  # The definition decides the two disability row tests, which are the only things that differ between fields:
  # * +answered_condition+ decides whether a row is an answer that can be the latest for its type.
  # * +qualifies_condition+ decides whether that row counts.
  #
  # Both rules reduce rows in SQL, so memory use doesn't grow with the number of enrollments or disability rows per
  # client (e.g. HMISs that create an enrollment per night-by-night shelter stay).
  #
  # Definitions:
  # * :any_reported - any Yes response, whether or not it is long-term or impairing.
  # * :hud - a Yes that meets HUD's Disabling Condition definition.
  class DisablingConditionInference
    include Hmis::Concerns::HmisArelHelper

    DEFINITIONS = [:hud, :any_reported].freeze

    DISABILITY_TYPE_CODES = GrdaWarehouse::Hud::Disability.disability_types.invert.freeze

    NO_YES_RESPONSES = [0, 1].freeze

    # Disability responses considered by the inference, matching the warehouse
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

    # @param eligibility_scope [EnrollmentEligibilityScope]
    # @param definition [Symbol] one of DEFINITIONS
    def initialize(eligibility_scope:, definition:)
      raise ArgumentError, "Unknown disabling condition definition #{definition.inspect}" unless definition.in?(DEFINITIONS)

      @eligibility_scope = eligibility_scope
      @definition = definition
    end

    # Returns true if rule A or B is Yes; false if either rule had a meaningful answer; nil if neither did.
    #
    # @param client_ids [Array<Integer>] destination client ids
    # @return [Hash{Integer => Boolean, nil}]
    def call(client_ids)
      return {} if client_ids.empty?

      enrollment_flags = disabling_condition_by_client(client_ids)
      disability_flags = disabled_because_disability_by_client(client_ids)

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

    private

    # Rule A. Warehouse counterpart: GrdaWarehouse::Hud::Client.disabling_condition_client_scope.
    # Picks the latest in-scope enrollment with a Yes/No DisablingCondition per client. Unlike the warehouse,
    # ties on EntryDate are broken deterministically, and WIP enrollments are included.
    #
    # Ranks enrollments in SQL so the result is one row per client, however many enrollments a client has.
    #
    # @return [Hash{Integer => Boolean}] clients without a Yes/No answer are absent
    def disabling_condition_by_client(client_ids)
      latest_first = Arel::Nodes::Window.new.
        partition(wc_t[:destination_id]).
        order(
          e_t[:EntryDate].desc.nulls_last,
          e_t[:DateUpdated].desc.nulls_last,
          e_t[:id].desc,
        )
      answered_enrollments = @eligibility_scope.call(client_ids).
        where(e_t[:DisablingCondition].in(NO_YES_RESPONSES)).
        select(
          wc_t[:destination_id].as('client_id'),
          e_t[:DisablingCondition].as('disabling_condition'),
          nf('ROW_NUMBER').over(latest_first).as('recency_rank'),
        )

      ranked = Arel::Table.new(:ranked_enrollments, type_caster: Hmis::Hud::Enrollment.type_caster)
      rows = Hmis::Hud::Enrollment.unscoped.
        from(answered_enrollments, ranked.name).
        where(ranked[:recency_rank].eq(1)).
        pluck(ranked[:client_id], ranked[:disabling_condition])

      rows.to_h.transform_values { |response| response == 1 }
    end

    # Rule B. Warehouse counterpart: GrdaWarehouse::Hud::Client.disabled_client_because_disability_scope.
    # Rows with a response of 0-3 that pass +answered_condition+ are candidates for "latest". For each disability
    # type, the type is positive if any row on its latest InformationDate passes +qualifies_condition+ (so a same-day
    # qualifying row wins, as in the warehouse). A later answered row replaces an earlier qualifying row of the same
    # type even if the later row does not qualify. Rows without an InformationDate are skipped.
    #
    # Reduces rows in SQL so the result is one row per client, however many disability rows a client has.
    #
    # @return [Hash{Integer => Boolean}] clients without any answered disability row are absent
    def disabled_because_disability_by_client(client_ids)
      latest_date_for_type = nf('MAX', [d_t[:InformationDate]]).over(
        Arel::Nodes::Window.new.partition([wc_t[:destination_id], d_t[:DisabilityType]]),
      )
      answered_rows = Hmis::Hud::Disability.
        joins(:enrollment).
        merge(@eligibility_scope.call(client_ids)).
        where(DisabilityType: DISABILITY_TYPE_CODES.values).
        where.not(InformationDate: nil).
        where(answered_condition).
        select(
          wc_t[:destination_id].as('client_id'),
          d_t[:InformationDate].as('information_date'),
          latest_date_for_type.as('latest_information_date'),
          qualifies_condition.as('qualifies'),
        )

      answered = Arel::Table.new(:answered_disabilities, type_caster: Hmis::Hud::Disability.type_caster)
      rows = Hmis::Hud::Disability.unscoped.
        from(answered_rows, answered.name).
        where(answered[:information_date].eq(answered[:latest_information_date])).
        group(answered[:client_id]).
        pluck(answered[:client_id], nf('BOOL_OR', [answered[:qualifies]]))

      rows.to_h.transform_values { |qualifies| qualifies == true }
    end

    # SQL test for whether a Disabilities row is an answer that can be the latest for its type.
    def answered_condition
      case @definition
      when :hud then hud_answered_condition
      when :any_reported then response_answered_condition
      end
    end

    # SQL test for whether a Disabilities row counts as disabled.
    def qualifies_condition
      case @definition
      when :hud then hud_qualifies_condition
      when :any_reported then yes_response_condition
      end
    end

    # Any No or Yes response, as in the warehouse.
    def response_answered_condition
      d_t[:DisabilityResponse].in(DISABILITY_RESPONSE_CODES)
    end

    # Any Yes response, whether or not it is long-term or impairing.
    def yes_response_condition
      d_t[:DisabilityResponse].in(DISABILITY_YES_RESPONSE_CODES)
    end

    def always_qualifying_type_condition
      d_t[:DisabilityType].in(ALWAYS_QUALIFYING_DISABILITY_TYPES)
    end

    # A Yes on a type that needs the IndefiniteAndImpairs follow-up is only an answer when that follow-up is No or
    # Yes. Leaving the follow-up blank (or 8/9/99) is missing data, so it does not replace an earlier qualifying row
    # of the same type.
    def hud_answered_condition
      no_response = d_t[:DisabilityResponse].eq(DISABILITY_NO_RESPONSE_CODE)
      follow_up_answered = d_t[:IndefiniteAndImpairs].in(NO_YES_RESPONSES)

      response_answered_condition.and(
        no_response.or(always_qualifying_type_condition).or(follow_up_answered),
      )
    end

    # Reference: GrdaWarehouse::Hud::Disability#indefinite_and_impairs?
    def hud_qualifies_condition
      indefinite_and_impairs = d_t[:IndefiniteAndImpairs].eq(INDEFINITE_AND_IMPAIRS_YES)

      yes_response_condition.and(
        always_qualifying_type_condition.or(indefinite_and_impairs),
      )
    end
  end
end
