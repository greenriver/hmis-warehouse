###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::DisabilityCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for clients with disabilities
    # @return [Hash] A hash containing report configurations for different disability categories
    def disability_detail_hash
      hash = {}.tap do |hashes|
        @filter.available_disabilities.each do |title, key|
          hashes["disability_#{key}"] = {
            title: "Disability #{title}",
            can_view_details: can_view_client_disability?(@filter.user, key),
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_disability(key)).distinct },
          }
        end
      end
      hash.merge!(
        'yes_disability' =>
          {
            title: 'At Least One Disability',
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_disabilities.keys).distinct },
          },
        'no_disability' =>
          {
            title: 'No Disability',
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: distinct_client_ids.pluck(:client_id).uniq - client_disabilities.keys).distinct },
          },
      )
    end

    # Counts the number of clients with a specific disability type
    # @param type [Symbol] The disability type to count
    # @return [Integer] The count of clients with the specified disability, masked if population is small
    def disability_count(type)
      mask_small_population(disability_breakdowns[type]&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific disability type
    # @param type [Symbol] The disability type to calculate percentage for
    # @return [Float] The percentage of clients with the specified disability
    def disability_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = disability_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Counts the number of clients with no disabilities
    # @return [Integer] The count of clients with no disabilities
    def no_disability_count
      @no_disability_count ||= total_client_count - client_disabilities_count
    end

    # Calculates the percentage of clients with no disabilities
    # @return [Float] The percentage of clients with no disabilities
    def no_disability_percentage
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = no_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Counts the number of clients with at least one disability
    # @return [Integer] The count of clients with at least one disability
    def yes_disability_count
      @yes_disability_count ||= client_disabilities_count
    end

    # Calculates the percentage of clients with at least one disability
    # @return [Float] The percentage of clients with at least one disability
    def yes_disability_percentage
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = yes_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares disability-related data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with disability data
    def disability_data_for_export(rows)
      rows['_Disability Break'] ||= []
      rows['*Indefinite and Impairing Disabilities'] ||= []
      rows['*Indefinite and Impairing Disabilities'] += ['Disability', nil, 'Count', 'Percentage', nil]
      @filter.available_disabilities.each do |title, id|
        rows["_Disabilities_data_#{title}"] ||= []
        rows["_Disabilities_data_#{title}"] += [
          title,
          nil,
          disability_count(id),
          disability_percentage(id) / 100,
        ]
      end
      rows['_At Least One Disability_data_'] ||= []
      rows['_At Least One Disability_data_'] += [
        'At Least One Disability',
        nil,
        yes_disability_count,
        yes_disability_percentage / 100,
      ]
      rows['_No Disability_data_'] ||= []
      rows['_No Disability_data_'] += [
        'No Disability',
        nil,
        no_disability_count,
        no_disability_percentage / 100,
      ]
      rows
    end

    # Counts the total number of clients with disabilities
    # @return [Integer] The count of clients with disabilities, masked if population is small
    private def client_disabilities_count
      @client_disabilities_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(client_disabilities.count)
      end
    end

    # Retrieves client IDs for a specific disability type
    # @param type [Symbol] The disability type to filter by
    # @return [Array] Array of client IDs with the specified disability
    def client_ids_in_disability(type)
      disability_breakdowns[type]
    end

    # Groups clients by their disability types
    # @return [Hash] A hash mapping disability types to sets of client IDs
    private def disability_breakdowns
      @disability_breakdowns ||= {}.tap do |disabilities|
        @filter.available_disabilities.each_value do |d|
          disabilities[d] ||= Set.new
          client_disabilities.each do |id, ds|
            disabilities[d] << id if ds.include?(d)
          end
        end
      end
    end

    # Retrieves and caches client disability information
    # @return [Hash] A hash mapping client IDs to sets of their disability types
    private def client_disabilities
      @client_disabilities ||= Rails.cache.fetch(disabilities_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          disabled_client_disability_types.each do |client_id, disability|
            clients[client_id] ||= Set.new
            clients[client_id] << disability
          end
        end
      end
    end

    # Retrieves disability types for disabled clients
    # @return [Array] Array of [client_id, disability_type] pairs
    private def disabled_client_disability_types
      ids = distinct_client_ids.pluck(:client_id)
      return [] unless ids.any?

      GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: ids).
        joins(:source_enrollment_disabilities).
        merge(
          GrdaWarehouse::Hud::Disability.
          where(GrdaWarehouse::Hud::Disability.indefinite_disability_arel),
        ).pluck(
          :id,
          d_t[:DisabilityType],
        )
    end

    # Generates the cache key for client disabilities
    # @return [Array] The cache key components
    private def disabilities_cache_key
      [self.class.name, cache_slug, 'client_disabilities']
    end
  end
end
