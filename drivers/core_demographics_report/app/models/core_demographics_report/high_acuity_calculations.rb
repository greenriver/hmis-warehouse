###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::HighAcuityCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for high acuity-related data
    # @return [Hash] A hash containing report configurations for different high acuity categories
    def high_acuity_detail_hash
      {}.tap do |hashes|
        available_high_acuity_types.invert.each do |key, title|
          hashes["high_acuity_#{key}"] = {
            title: "High Acuity - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: high_acuity_client_ids(key)).distinct },
          }
        end
      end
    end

    # Counts the number of clients with a specific high acuity type
    # @param type [Symbol] The high acuity type to count
    # @param coc [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Integer] The count of clients with the specified high acuity type, masked if population is small
    def high_acuity_count(type, coc = base_count_sym)
      mask_small_population(high_acuity_client_ids(type, coc)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific high acuity type
    # @param type [Symbol] The high acuity type to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Float] The percentage of clients with the specified high acuity type
    def high_acuity_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      # We want the percentage based on the total high acuity households for the hh breakdowns
      total_count = high_acuity_count(:household, coc_code) unless type.in?([:client, :household])
      # Clients with one disability should use clients in the category as a denominator
      total_count = high_acuity_count(:client, coc_code) if type == :one_disability
      return 0 if total_count.zero?

      of_type = high_acuity_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares high acuity-related data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with high acuity data
    def high_acuity_data_for_export(rows)
      rows['_High Acuity Type'] ||= []
      rows['*High Acuity Type'] ||= []
      rows['*High Acuity Type'] += ['High Acuity Type', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*High Acuity Type'] += ["#{coc_code} Client"]
        rows['*High Acuity Type'] += ["#{coc_code} Percentage"]
      end
      rows['*High Acuity Type'] += [nil]
      available_high_acuity_types.invert.each do |id, title|
        rows["_High Acuity Type_data_#{title}"] ||= []
        rows["_High Acuity Type_data_#{title}"] += [
          title,
          nil,
          high_acuity_count(id),
          high_acuity_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_High Acuity Type_data_#{title}"] += [
            high_acuity_count(id, coc_code.to_sym),
            high_acuity_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    # Retrieves client IDs for a specific high acuity type and CoC
    # @param key [Symbol] The high acuity type to filter by
    # @param coc_code [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Array] Array of client IDs with the specified high acuity type
    private def high_acuity_client_ids(key, coc_code = base_count_sym)
      # These three are stored as client_ids, the remaining are enrollment, client_id pairs
      if key.in?([:client, :household, :one_disability])
        high_acuity_clients[key][coc_code]
      else
        # fetch client_ids from Set[[enrollment_id, client_id]]
        high_acuity_clients[key][coc_code].to_a.map(&:last).uniq
      end
    end

    # Retrieves client IDs for heads of households
    # @return [Array] Array of client IDs who are heads of households
    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    # Returns a hash of available high acuity types and their corresponding keys
    # @return [Hash] A hash mapping display names to high acuity type symbols
    def available_high_acuity_types
      {
        'Client' => :client,
        'Household' => :household,
        'Adult only Households' => :without_children,
        'Adult and Child Households' => :with_children,
        'Child only Households' => :only_children,
        'Youth only Households' => :unaccompanied_youth,
        'Clients with only 1 Disability' => :one_disability,
      }
    end

    # Initializes the data structure for tracking high acuity clients
    # @param clients [Hash] The hash to store client data
    # @param coc_code [Symbol] The CoC code to initialize for (defaults to base_count_sym)
    private def initialize_high_acuity_client_counts(clients, coc_code = base_count_sym)
      available_high_acuity_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
    end

    # Updates the counts of high acuity clients for various categories
    # @param clients [Hash] The hash storing client data
    # @param client_id [Integer] The ID of the client to process
    # @param enrollment_id [Integer] The ID of the enrollment to process
    # @param coc_code [Symbol] The CoC code to update for (defaults to base_count_sym)
    private def set_high_acuity_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
      # Only count HoH for household counts, and only count them in one category.
      if !clients[:client][coc_code].include?(client_id) && hoh_client_ids.include?(client_id)
        # These need to use enrollment.id to capture age correctly, but needs the client for summary counts
        clients[:without_children][coc_code] << [enrollment_id, client_id] if without_children.include?(enrollment_id)
        clients[:with_children][coc_code] << [enrollment_id, client_id] if with_children.include?(enrollment_id)
        clients[:only_children][coc_code] << [enrollment_id, client_id] if only_children.include?(enrollment_id)
        clients[:unaccompanied_youth][coc_code] << [enrollment_id, client_id] if unaccompanied_youth.include?(enrollment_id)
      end
      # Always add them to the clients category
      clients[:client][coc_code] << client_id
      clients[:household][coc_code] << client_id if hoh_client_ids.include?(client_id)
    end

    # Retrieves and caches high acuity client information
    # @return [Hash] A hash containing sets of client IDs for different high acuity categories
    private def high_acuity_clients
      @high_acuity_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_high_acuity_types.invert.each do |key, _|
            clients[key] = {}
          end

          ([base_count_sym] + available_coc_codes).each do |coc_code|
            initialize_high_acuity_client_counts(clients, coc_code.to_sym)

            scope = report_scope.distinct
            scope = scope.in_enrollment_coc(coc_code: coc_code) unless coc_code == base_count_sym
            scope.
              joins(:client, enrollment: :disabilities).
              pluck(:client_id, :id, e_t[:TimesHomelessPastThreeYears], e_t[:DisablingCondition], d_t[:DisabilityType], d_t[:DisabilityResponse], d_t[:IndefiniteAndImpairs]).
              group_by(&:shift).
              each do |client_id, rows|
                counts_by_enrollment = {}

                # Don't count anyone we've already counted in the chronic counts
                next if chronic_clients[:client][coc_code]&.include?(client_id)

                enrollments = rows.group_by { |e| [e.shift, e.shift, e.shift] }
                enrollments.each do |(enrollment_id, times_homeless, disabling_condition), disabilities|
                  # Exclude 8, 9, & 99 responses. Assume this enrollment consitutes 1 episode
                  next if times_homeless.nil? || times_homeless > 4

                  counted_disabilities = Set.new
                  disabilities.each do |d_type, response, indefinite|
                    next unless response.in?(GrdaWarehouse::Hud::Disability.positive_responses)

                    # developmental and hiv are always indefinite and impairing
                    if d_type.in?([6, 8])
                      counted_disabilities << d_type
                    elsif indefinite == 1
                      counted_disabilities << d_type
                    end
                  end
                  # Only count disabling condition if there are no supporting disability details
                  counted_disabilities << :disabling_condition if disabling_condition == 1 && counted_disabilities.count.zero?

                  counts_by_enrollment[enrollment_id] = counted_disabilities.count
                end
                counts = counts_by_enrollment.values
                # Count any client who has one disability (and never reported more than one)
                if counts.max == 1
                  clients[:one_disability][coc_code.to_sym] << client_id
                  # Don't count anyone with only one or no disabling condition
                  next
                end
                counts_by_enrollment.each do |enrollment_id, count|
                  next if count < 2

                  set_high_acuity_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
                end
              end
          end
        end
      end
    end
  end
end
