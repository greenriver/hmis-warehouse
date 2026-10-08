###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Resolves household.* field values for destination clients in batch, from the household chosen by HouseholdSelector.
  #
  # size counts open member enrollments, including members with no DOB.
  # Member ages use each member's destination client DOB; members without one are ignored for ages.
  # Clients with no open in-scope household resolve to nil.
  class HouseholdValueResolver
    include Hmis::Concerns::HmisArelHelper

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # @return [Hash{Integer => Integer, nil}]
    def call(clients, field)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      selected, members = households_for(client_ids)

      client_ids.index_with do |client_id|
        # nil when the client has no open in-scope household, or when the selected household lost its open
        # members between the selector and member queries (concurrent exit/delete)
        ages = members[selected[client_id]]
        next nil unless ages

        case field.key
        when HouseholdFieldRegistry::SIZE.key
          ages.size
        when HouseholdFieldRegistry::YOUNGEST_MEMBER_AGE.key
          ages.compact.min
        when HouseholdFieldRegistry::OLDEST_MEMBER_AGE.key
          ages.compact.max
        else
          raise ArgumentError, "Unknown household field \"#{field.key}\""
        end
      end
    end

    private

    # ClientPoolEvaluator resolves each household.* field separately for the same batch, so reuse the
    # selection and ages when the client ids repeat. Only the most recent batch is kept.
    def households_for(client_ids)
      return @last_households if @last_client_ids == client_ids

      selected = HouseholdSelector.new(configuration: @configuration).call(client_ids)
      @last_client_ids = client_ids
      @last_households = [selected, member_ages_by_household(selected.values.uniq)]
    end

    # @return [Hash{Array(Integer, String) => Array<Integer, nil>}] household => one age per open member enrollment
    def member_ages_by_household(households)
      rows = Hmis::HouseholdMembership.open_enrollments(households).
        left_outer_joins(client: :warehouse_client_source).
        pluck(e_t[:data_source_id], e_t[:HouseholdID], wc_t[:destination_id])

      # Same age expression as current_age, so the two agree
      ages = AgeCalculator.new(@current_date).call(GrdaWarehouse::Hud::Client.where(id: rows.map(&:last).compact.uniq))

      rows.group_by { |data_source_id, household_id, _| [data_source_id, household_id] }.
        transform_values { |household_rows| household_rows.map { |_, _, destination_id| ages[destination_id] } }
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
