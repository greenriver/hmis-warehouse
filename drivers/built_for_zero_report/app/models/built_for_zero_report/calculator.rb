###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  # Calculator for BFZ report.
  #
  # SourceDataHash fields:
  #    * client_id [Integer] the destination client ID
  #    * first_name [String] the client first name
  #    * last_name [String] the client last name
  #    * change [String] one of 'create' | 'destroy' ('deactivate' is not used for system cohorts)
  #    * reason [String] one of:
  #        - 'Newly identified' (create)
  #        - 'Returned from housing' (create)
  #        - 'Returned from inactive' (create)
  #        - 'Housed' (destroy)
  #        - 'Inactive' (destroy)
  #        - 'No longer meets criteria'(destroy)
  #    * changed_at [Date] the date of the change
  class Calculator
    include ArelHelper

    # @param cohort_key [Symbol] The system cohort key (from GrdaWarehouse::SystemCohorts::Base.cohort_classes)
    # @param start_date [Date] The start of the reporting range
    # @param end_date [Date] The end of the reporting range
    # @param client_ids [Set, nil] If defined, limit the clients to the specified destination client ids
    def initialize(cohort_key, start_date, end_date, client_ids: nil)
      @cohort_id = GrdaWarehouse::SystemCohorts::Base.find_system_cohort(cohort_key).id
      @start_date = start_date
      @end_date = end_date
      @client_ids = client_ids
    end

    # @return [SourceDataHash] actively homeless clients in cohort during the reporting period
    def actively_homeless
      source_data.reject { |_, v| v[:change] == 'destroy' } # Remove clients who exited
    end

    # :section: Outflow

    # @return [SourceDataHash] clients in cohort who were housed in the reporting period
    def housed
      source_data.select { |_, v| v[:change] == 'destroy' && v[:reason] == 'Housed' }
    end

    # @return a pair:
    #   clients in cohort who were housed in the reporting period extended with:
    #       * the entry date of their first enrollment in HMIS,
    #       * the number of days between that date, and their housed date.
    #   and the average length of time to housing for the housed clients in the cohort
    def average_lot_to_housing
      client_count = lot_to_housing.count
      sum_of_days = lot_to_housing.map { |_, v| v[:lot_to_housing] }.sum
      sum_of_days / client_count.to_f # TODO Rounding?
    end

    # @return [SourceDataHash] clients in cohort who became inactive in the reporting period
    def inactive
      source_data.select { |_, v| v[:change] == 'destroy' && v[:reason] == 'Inactive' }
    end

    # @return [SourceDataHash] clients who ceased to be eligible for inclusion in the cohort during the reporting period
    def ineligible
      source_data.select { |_, v| v[:change] == 'destroy' && v[:reason] == 'No longer meets criteria' }
    end

    # :section: Inflow

    # @return [SourceDataHash] clients in cohort who were newly identified in the reporting period
    def newly_identified
      source_data.select { |_, v| v[:change] == 'create' && v[:reason] == 'Newly Identified' }
    end

    # @return [SourceDataHash] clients in cohort who returned to homelessness from housing in the reporting period
    def returned_from_housing
      source_data.select { |_, v| v[:change] == 'create' && v[:reason] == 'Returned from housing' }
    end

    # @return [SourceDataHash] clients who returned to the cohort after a period of inactivity in the reporting period
    def returned_from_inactivity
      source_data.select { |_, v| v[:change] == 'create' && v[:reason] == 'Returned from inactive' }
    end

    # Roll up of a cohort change history to reflect most recent change for each client on a specified date.
    # @return [scope] GrdaWarehouse::Hud::Clients joined with GrdaWarehouse::CohortClientChange
    private def source_scope
      mrc_t = Arel::Table.new(:most_recent_changes)
      join = c_c_change_t.join(mrc_t).on(c_c_change_t[:id].eq(mrc_t[:current_id]))

      GrdaWarehouse::Hud::Client.
        with(
          most_recent_changes:
            GrdaWarehouse::CohortClientChange.
              define_window(:cohort_client_id_by_change_date).partition_by(c_c_change_t[:cohort_client_id], order_by: { c_c_change_t[:changed_at] => :desc }).
              select_window(:first_value, c_c_change_t[:id], over: :cohort_client_id_by_change_date, as: :current_id).
              where(cohort_id: @cohort_id).
              where(c_c_change_t[:changed_at].lteq(@end_date)),
        ).
        joins(cohort_clients: :cohort_client_changes).
        joins(join.join_sources)
    end

    # Get the source data from specified cohort in the reporting period.
    # @return [Hash{Integer => Hash}] Hash of destination client IDs to source data hashes
    private def source_data
      @source_data ||= begin
        fields = {
          client_id: c_t[:id], # Client ID must be first as it is used as the hash key
          first_name: c_t[:FirstName],
          last_name: c_t[:LastName],
          change: c_c_change_t[:change],
          reason: c_c_change_t[:reason],
          changed_at: c_c_change_t[:changed_at],
        }
        data = source_scope.
          pluck(*([c_t[:id]] + fields.values)).
          group_by(&:first).
          transform_values { |arr| fields.keys.zip(arr.flatten).to_h }.
          reject { |_, v| v[:change] == 'destroy' && v[:changed_at] < @start_date } # Only include exits in the reporting period

        data = data.keep_if { |k, _| k.in?(@client_ids) } if @client_ids.present?
        data
      end
    end

    # Extend the source data hash from the housed clients to include LOT data
    # @return [Hash{Integer => Hash}] Hash of destination client IDs to extended source data hashes
    def lot_to_housing
      @lot_to_housing ||= begin
        housed_clients = housed
        first_enrollment_dates = GrdaWarehouse::ServiceHistoryEnrollment.
          first_date.
          where(client_id: housed_clients.keys).pluck(:client_id, :first_date_in_program).
          to_h
        housed_clients.map do |client_id, data|
          first_date = first_enrollment_dates[client_id]
          data.merge!(
            {
              identification_date: first_date,
              lot_to_housing: (data[:changed_at].to_date - first_date).to_i,
            },
          )
        end
        housed_clients
      end
    end
  end
end
