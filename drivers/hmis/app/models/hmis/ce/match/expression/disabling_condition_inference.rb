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
  # * +answered?+ decides whether a row is an answer that can be the latest for its type.
  # * +qualifies?+ decides whether that row counts.
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

    # A Disabilities row plucked for rule B
    DisabilityRow = Data.define(:client_id, :type, :response, :indefinite_and_impairs, :information_date)

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
    # @return [Hash{Integer => Boolean}] clients without a Yes/No answer are absent
    def disabling_condition_by_client(client_ids)
      ordering = [
        e_t[:EntryDate].desc.nulls_last,
        e_t[:DateUpdated].desc.nulls_last,
        e_t[:id].desc,
      ]
      rows = @eligibility_scope.call(client_ids).
        where(e_t[:DisablingCondition].in(NO_YES_RESPONSES)).
        order(*ordering).
        pluck(wc_t[:destination_id], e_t[:DisablingCondition])

      latest_row_by_client = rows.group_by(&:first).transform_values(&:first)
      latest_row_by_client.transform_values { |(_client_id, response)| response == 1 }
    end

    # Rule B. Warehouse counterpart: GrdaWarehouse::Hud::Client.disabled_client_because_disability_scope.
    # Rows with a response of 0-3 that pass +answered?+ are candidates for "latest". For each disability type, the
    # type is positive if any row on its latest InformationDate passes +qualifies?+ (so a same-day qualifying row
    # wins, as in the warehouse). A later answered row replaces an earlier qualifying row of the same type even if
    # the later row does not qualify. Rows without an InformationDate are skipped.
    #
    # @return [Hash{Integer => Boolean}] clients without any answered disability row are absent
    def disabled_because_disability_by_client(client_ids)
      disability_scope = Hmis::Hud::Disability.
        where(
          DisabilityType: DISABILITY_TYPE_CODES.values,
          DisabilityResponse: DISABILITY_RESPONSE_CODES,
        ).
        where.not(InformationDate: nil)

      in_scope_rows = disability_scope.
        joins(:enrollment).
        merge(@eligibility_scope.call(client_ids))
      plucked_rows = in_scope_rows.pluck(
        wc_t[:destination_id],
        d_t[:DisabilityType],
        d_t[:DisabilityResponse],
        d_t[:IndefiniteAndImpairs],
        d_t[:InformationDate],
      )
      all_rows = plucked_rows.map { |values| DisabilityRow.new(*values) }
      answered_rows = all_rows.select { |row| answered?(row) }

      rows_by_client = answered_rows.group_by(&:client_id)
      rows_by_client.transform_values do |client_rows|
        rows_by_type = client_rows.group_by(&:type)
        rows_by_type.values.any? { |type_rows| latest_rows_qualify?(type_rows) }
      end
    end

    # True if any row on the latest InformationDate in +type_rows+ passes +qualifies?+.
    def latest_rows_qualify?(type_rows)
      latest_date = type_rows.map(&:information_date).max
      latest_rows = type_rows.select { |row| row.information_date == latest_date }
      latest_rows.any? { |row| qualifies?(row) }
    end

    def answered?(row)
      case @definition
      when :hud then hud_row_answered?(row)
      when :any_reported then response_answered?(row)
      end
    end

    def qualifies?(row)
      case @definition
      when :hud then hud_row_qualifies?(row)
      when :any_reported then yes_response?(row)
      end
    end

    # Any No or Yes response, as in the warehouse.
    def response_answered?(row)
      row.response.in?(DISABILITY_RESPONSE_CODES)
    end

    # Any Yes response, whether or not it is long-term or impairing.
    def yes_response?(row)
      row.response.in?(DISABILITY_YES_RESPONSE_CODES)
    end

    # A Yes on a type that needs the IndefiniteAndImpairs follow-up is only an answer when that follow-up is No or
    # Yes. Leaving the follow-up blank (or 8/9/99) is missing data, so it does not replace an earlier qualifying row
    # of the same type.
    def hud_row_answered?(row)
      return false unless response_answered?(row)
      return true unless yes_response?(row)
      return true if row.type.in?(ALWAYS_QUALIFYING_DISABILITY_TYPES)

      row.indefinite_and_impairs.in?(NO_YES_RESPONSES)
    end

    # Reference: GrdaWarehouse::Hud::Disability#indefinite_and_impairs?
    def hud_row_qualifies?(row)
      return false unless yes_response?(row)
      return true if row.type.in?(ALWAYS_QUALIFYING_DISABILITY_TYPES)

      row.indefinite_and_impairs == INDEFINITE_AND_IMPAIRS_YES
    end
  end
end
