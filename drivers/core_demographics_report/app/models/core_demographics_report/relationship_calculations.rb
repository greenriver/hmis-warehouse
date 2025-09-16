###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::RelationshipCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for relationship to head of household data
    # @return [Hash] A hash containing report configurations for different relationship types
    def relationship_detail_hash
      {}.tap do |hashes|
        ::HudUtility2024.relationships_to_hoh.each do |key, title|
          hashes["relationship_#{key}"] = {
            title: "Relationship #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_relationship(key)).distinct },
          }
        end
      end
    end

    # Counts the number of clients with a specific relationship to head of household
    # @param type [Integer] The relationship type to count
    # @return [Integer] The count of clients with the specified relationship type, masked if population is small
    def relationship_count(type)
      mask_small_population(relationship_breakdowns[type]&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific relationship to head of household
    # @param type [Integer] The relationship type to calculate percentage for
    # @return [Float] The percentage of clients with the specified relationship type
    def relationship_percentage(type)
      total_count = mask_small_population(client_relationships.count)
      return 0 if total_count.zero?

      of_type = relationship_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares relationship to head of household data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with relationship data
    def relationship_data_for_export(rows)
      rows['_Relationship to Head of Household Break'] ||= []
      rows['*Relationship to Head of Household'] ||= []
      rows['*Relationship to Head of Household'] += ['Relationship', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.relationships_to_hoh.each do |id, title|
        rows["_Relationship_data_#{title}"] ||= []
        rows["_Relationship_data_#{title}"] += [
          title,
          nil,
          relationship_count(id),
          relationship_percentage(id) / 100,
        ]
      end
      rows
    end

    # Groups clients by their relationship to head of household
    # @return [Hash] A hash mapping relationship types to sets of client IDs
    private def relationship_breakdowns
      @relationship_breakdowns ||= client_relationships.group_by do |_, v|
        v
      end
    end

    # Retrieves client IDs for a specific relationship to head of household
    # @param key [Integer] The relationship type to filter by
    # @return [Array] Array of client IDs with the specified relationship type
    private def client_ids_in_relationship(key)
      relationship_breakdowns[key]&.map(&:first)
    end

    # Retrieves and caches client relationship to head of household information
    # @return [Hash] A hash mapping client IDs to their relationship to head of household
    private def client_relationships
      @client_relationships ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:enrollment).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, e_t[:RelationshipToHoH], :first_date_in_program).
            each do |client_id, relationship, _|
              clients[client_id] ||= relationship
            end
        end
      end
    end
  end
end
