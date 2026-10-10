###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Resolves household.* field values for destination clients in batch, from the household chosen by HouseholdSelector.
  #
  # size counts the people with an open member enrollment, including members with no DOB.
  # Member ages use each member's destination client DOB; members without one are ignored for ages.
  # Clients with no open in-scope household resolve to nil.
  class HouseholdValueResolver
    Batch = Data.define(:client_ids, :households_by_client_id, :ages_by_destination_id) do
      # @return [Array<Integer>] ages of the household's members that have a DOB
      def member_ages(household)
        household.member_destination_ids.filter_map { |destination_id| ages_by_destination_id[destination_id] }
      end
    end

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # @return [Hash{Integer => Integer, nil}]
    def call(clients, field)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      batch = batch_for(client_ids)

      client_ids.index_with do |client_id|
        household = batch.households_by_client_id[client_id]
        next nil unless household

        case field.key
        when HouseholdFieldRegistry::SIZE.key
          household.size
        when HouseholdFieldRegistry::YOUNGEST_MEMBER_AGE.key
          batch.member_ages(household).min
        when HouseholdFieldRegistry::OLDEST_MEMBER_AGE.key
          batch.member_ages(household).max
        else
          raise ArgumentError, "Unknown household field \"#{field.key}\""
        end
      end
    end

    private

    # ClientPoolEvaluator resolves each household.* field separately for the same clients, so the last batch is
    # reused when the client ids match, in any order.
    def batch_for(client_ids)
      client_id_set = client_ids.to_set
      return @last_batch if @last_batch&.client_ids == client_id_set

      households_by_client_id = HouseholdSelector.new(configuration: @configuration).call(client_ids)
      member_ids = households_by_client_id.values.flat_map(&:member_destination_ids).uniq
      # Same age expression as current_age, so the two agree
      ages_by_destination_id = AgeCalculator.new(@current_date).call(GrdaWarehouse::Hud::Client.where(id: member_ids))

      @last_batch = Batch.new(
        client_ids: client_id_set,
        households_by_client_id: households_by_client_id,
        ages_by_destination_id: ages_by_destination_id,
      )
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
