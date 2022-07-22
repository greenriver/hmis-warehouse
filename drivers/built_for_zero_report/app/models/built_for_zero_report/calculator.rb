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
    # @param client_ids [Array, nil] If defined, an array of string representations of the keys we will send to the API
    def initialize(cohort_key, start_date, end_date, user:, client_ids: nil, data_keys: nil)
      @cohort_id = GrdaWarehouse::SystemCohorts::Base.find_system_cohort(cohort_key).id
      @data_keys = data_keys.presence || default_data_keys
      @start_date = start_date.to_date
      @end_date = end_date.to_date
      @client_ids = client_ids
      @user = user
      @interval = if @start_date + 1.months - 1.days == @end_date
        '1 month'
      else
        "#{(@end_date - @start_date).to_i} days"
      end
    end

    def for_api(sub_population_id)
      data = {
        'subpopulation_id' => sub_population_id,
        'actively_homeless' => actively_homeless.count,
        'avg_lot_from_id_to_housing' => average_lot_to_housing,
        'housing_placements' => housed.count,
        'moved_to_inactive' => inactive.count,
        'no_longer_meets_population_criteria' => ineligible.count,
        'newly_identified' => newly_identified.count,
        'returned_from_housing' => returned_from_housing.count,
        'returned_from_inactive' => returned_from_inactivity.count,
        'name' => @user.name,
        'email' => @user.email,
        'organization' => @user.agency_name,
        'date_interval_start' => @start_date.to_time.utc.strftime('%FT%T.000Z'), # match API format
        'date_interval' => @interval,
      }
      data.delete_if { |k, _| !@data_keys.include?(k) }
    end

    def default_data_keys
      [
        'subpopulation_id',
        'actively_homeless',
        'avg_lot_from_id_to_housing',
        'housing_placements',
        'moved_to_inactive',
        'no_longer_meets_population_criteria',
        'newly_identified',
        'returned_from_housing',
        'returned_from_inactive',
        'name',
        'email',
        'organization',
        'date_interval_start',
        'date_interval',
      ]
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
      return 'Unknown' if client_count.zero?

      sum_of_days = lot_to_housing.map { |_, v| v[:lot_to_housing] }.sum
      (sum_of_days / client_count.to_f).round
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
          pluck(*fields.values).
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
        # We are looking for the first recorded date of homelessness:
        #
        # 1. Get the earlier of 3.917.3 DateToStreetESSH or 3.10.1 EntryDate for any Enrollments where
        #    3.917 Prior Living Situation indicates homelessness:
        first_enrollment_dates = GrdaWarehouse::ServiceHistoryEnrollment.
          joins(:enrollment).
          entry.
          where(client_id: housed.keys).
          where(e_t[:LivingSituation].in(HUD.homeless_situations(as: :prior))).
          pluck(:client_id, e_t[:DateToStreetESSH], e_t[:EntryDate]).
          group_by(&:shift).
          transform_values { |dates| dates.flatten.compact.min }

        # 2. Consider any 3.10.1 EntryDate for any Enrollments where the associated 2.02.6 ProjectType suggests
        #    homelessness:
        homeless_project_dates = GrdaWarehouse::ServiceHistoryEnrollment.
          joins(enrollment: :project).
          entry.
          where(client_id: housed.keys).
          merge(GrdaWarehouse::Hud::Project.homeless).
          group(:client_id).
          minimum(e_t[:EntryDate])
        first_enrollment_dates.merge!(homeless_project_dates) { |_, old, new| [old, new].min }

        # 3. And also consider the earliest 4.12.1 InformationDate where 4.12.2 CurrentLivingSituation indicates
        #    homelessness
        homeless_contact_dates = GrdaWarehouse::ServiceHistoryEnrollment.
          joins(enrollment: :current_living_situations).
          entry.
          where(client_id: housed.keys).
          where(cls_t[:CurrentLivingSituation].in(HUD.homeless_situations(as: :current))).
          group(:client_id).
          minimum(cls_t[:InformationDate])
        first_enrollment_dates.merge!(homeless_contact_dates) { |_, old, new| [old, new].min }

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
