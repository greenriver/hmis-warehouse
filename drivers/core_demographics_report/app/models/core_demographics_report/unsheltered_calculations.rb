###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::UnshelteredCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for unsheltered client data
    # @return [Hash] A hash containing report configurations for different unsheltered client categories
    def unsheltered_detail_hash
      {}.tap do |hashes|
        available_unsheltered_types.invert.each do |key, title|
          hashes["unsheltered_#{key}"] = {
            title: "Unsheltered - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: unsheltered_client_ids(key)).distinct },
          }
        end
      end
    end

    # Counts the number of unsheltered clients of a specific type
    # @param type [Symbol] The type of unsheltered client to count
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of unsheltered clients of the specified type, masked if population is small
    def unsheltered_count(type, coc_code = base_count_sym)
      mask_small_population(unsheltered_client_ids(type, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of unsheltered clients of a specific type
    # @param type [Symbol] The type of unsheltered client to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of unsheltered clients of the specified type
    def unsheltered_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      # We want the percentage based on the total unsheltered households for the hh breakdowns
      total_count = unsheltered_count(:household, coc_code) unless type.in?([:client, :household])
      return 0 if total_count.zero?

      of_type = unsheltered_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares unsheltered client data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with unsheltered client data
    def unsheltered_data_for_export(rows)
      rows['_Unsheltered'] ||= []
      rows['*Unsheltered and Active in Street Outreach'] ||= []
      rows['*Unsheltered and Active in Street Outreach'] += ['Unsheltered and Active in Street Outreach', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Unsheltered and Active in Street Outreach'] += ["#{coc_code} Client"]
        rows['*Unsheltered and Active in Street Outreach'] += ["#{coc_code} Percentage"]
      end
      rows['*Unsheltered and Active in Street Outreach'] += [nil]
      available_unsheltered_types.invert.each do |id, title|
        rows["_Unsheltered_data_#{title}"] ||= []
        rows["_Unsheltered_data_#{title}"] += [
          title,
          nil,
          unsheltered_count(id),
          unsheltered_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Unsheltered_data_#{title}"] += [
            unsheltered_count(id, coc_code.to_sym),
            unsheltered_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    # Retrieves client IDs for a specific unsheltered type and CoC code
    # @param key [Symbol] The unsheltered type to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Array] Array of client IDs matching the specified criteria
    private def unsheltered_client_ids(key, coc_code = base_count_sym)
      # These two are stored as client_ids, the remaining are enrollment, client_id pairs
      if key.in?([:client, :household])
        unsheltered_clients[key][coc_code]
      else
        # fetch client_ids from Set[[enrollment_id, client_id]]
        unsheltered_clients[key][coc_code].to_a.map(&:last).uniq
      end
    end

    # Retrieves client IDs for heads of household
    # @return [Array] Array of client IDs who are heads of household
    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    # Defines the available types of unsheltered clients
    # @return [Hash] A hash mapping display names to unsheltered client type symbols
    def available_unsheltered_types
      {
        'Client' => :client,
        'Household' => :household,
        'Adult only Households' => :without_children,
        'Adult and Child Households' => :with_children,
        'Child only Households' => :only_children,
        'Youth only Households' => :unaccompanied_youth,
      }
    end

    # Initializes the unsheltered client counts for a specific CoC code
    # @param clients [Hash] The hash to store client counts
    # @param coc_code [Symbol] The CoC code to initialize for, defaults to base_count_sym
    private def initialize_unsheltered_client_counts(clients, coc_code = base_count_sym)
      available_unsheltered_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
    end

    # Sets the unsheltered client counts for a specific client and enrollment
    # @param clients [Hash] The hash to store client counts
    # @param client_id [Integer] The client ID to count
    # @param enrollment_id [Integer] The enrollment ID to count
    # @param coc_code [Symbol] The CoC code to count for, defaults to base_count_sym
    private def set_unsheltered_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
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

    # Retrieves and caches unsheltered client data
    # @return [Hash] A hash containing sets of client IDs organized by unsheltered type and CoC code
    private def unsheltered_clients
      @unsheltered_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_unsheltered_types.invert.each do |key, _|
            clients[key] = {}
          end

          initialize_unsheltered_client_counts(clients)

          report_scope.distinct.
            in_project_type(HudUtility2024.project_type_number('Street Outreach')).
            # checks SHS which equates to CLS
            with_service_between(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :id, :first_date_in_program).
            each do |client_id, enrollment_id, _|
              set_unsheltered_client_counts(clients, client_id, enrollment_id)
            end
          available_coc_codes.each do |coc_code|
            initialize_unsheltered_client_counts(clients, coc_code.to_sym)

            report_scope.distinct.in_enrollment_coc(coc_code: coc_code).
              in_project_type(HudUtility2024.project_type_number('Street Outreach')).
              # checks SHS which equates to CLS
              with_service_between(start_date: filter.start_date, end_date: filter.end_date).
              order(first_date_in_program: :desc).
              pluck(:client_id, :id, :first_date_in_program).
              each do |client_id, enrollment_id, _|
                set_unsheltered_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
              end
          end
        end
      end
    end
  end
end
