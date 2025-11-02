# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    class IdentifyDuplicatesQueryMatcher
      MATCH_TYPES = [:existing, :unprocessed].freeze

      SSN_FILTERS = [
        %(clients."SSN" IS NOT NULL),
        %(clients."SSN" != ''),
        %(clients."SSN" != '000000000'),
        %(clients."SSN" != '111111111'),
        %(clients."SSN" != '123456789'),
        %(LEFT(clients."SSN", 3) != '999'),
        %(LEFT(clients."SSN", 1) NOT IN ('x', 'X')),
        %(RIGHT(clients."SSN", 1) NOT IN ('x', 'X')),
      ].freeze

      NAME_PRESENCE_FILTERS = [
        %(clients."FirstName" IS NOT NULL),
        %(trim(clients."FirstName") != ''),
        %(clients."LastName" IS NOT NULL),
        %(trim(clients."LastName") != ''),
      ].freeze

      DOB_FILTERS = [
        %(clients."DOB" IS NOT NULL),
        %(date_part('year', clients."DOB") > 1920),
      ].freeze

      NORMALIZED_NAME_SQL = <<-SQL.squish.freeze
        concat(
          regexp_replace(lower(trim(unaccent(clients."FirstName"))), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(unaccent(clients."LastName"))), '[^a-z0-9]', '', 'g')
        )
      SQL

      # Executes SSN match query and returns processed ID pairs
      # @param match_type [Symbol] :existing or :unprocessed
      # @param warehouse_id [Integer] Optional warehouse data source ID (defaults to system warehouse)
      # @param destination_data_source_ids [Array<Integer>] Required for :unprocessed match_type
      # @param unprocessed_ids [Array<Integer>] Required for :unprocessed match_type
      # @param validate_ssn [Boolean] Whether to validate SSNs using HudHelper (default: true for SSN matches)
      # @return [Array<Array<Integer>>] Array of ID pairs
      def self.execute_ssn_matches(match_type:, warehouse_id: nil, destination_data_source_ids: nil, unprocessed_ids: nil, validate_ssn: true)
        return [] if match_type == :unprocessed && unprocessed_ids.blank?

        matcher = for_ssn_matches(
          match_type: match_type,
          warehouse_id: warehouse_id || GrdaWarehouse::DataSource.warehouse_id,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
        matcher.execute(validate_ssn: validate_ssn)
      end

      # Executes name match query and returns processed ID pairs
      # @param match_type [Symbol] :existing or :unprocessed
      # @param warehouse_id [Integer] Optional warehouse data source ID (defaults to system warehouse)
      # @param destination_data_source_ids [Array<Integer>] Required for :unprocessed match_type
      # @param unprocessed_ids [Array<Integer>] Required for :unprocessed match_type
      # @return [Array<Array<Integer>>] Array of ID pairs
      def self.execute_name_matches(match_type:, warehouse_id: nil, destination_data_source_ids: nil, unprocessed_ids: nil)
        return [] if match_type == :unprocessed && unprocessed_ids.blank?

        matcher = for_name_matches(
          match_type: match_type,
          warehouse_id: warehouse_id || GrdaWarehouse::DataSource.warehouse_id,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
        matcher.execute
      end

      # Executes DOB match query and returns processed ID pairs
      # @param match_type [Symbol] :existing or :unprocessed
      # @param warehouse_id [Integer] Optional warehouse data source ID (defaults to system warehouse)
      # @param destination_data_source_ids [Array<Integer>] Required for :unprocessed match_type
      # @param unprocessed_ids [Array<Integer>] Required for :unprocessed match_type
      # @return [Array<Array<Integer>>] Array of ID pairs
      def self.execute_dob_matches(match_type:, warehouse_id: nil, destination_data_source_ids: nil, unprocessed_ids: nil)
        return [] if match_type == :unprocessed && unprocessed_ids.blank?

        matcher = for_dob_matches(
          match_type: match_type,
          warehouse_id: warehouse_id || GrdaWarehouse::DataSource.warehouse_id,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
        matcher.execute
      end

      def self.for_ssn_matches(match_type:, warehouse_id:, destination_data_source_ids: nil, unprocessed_ids: nil)
        ensure_match_type!(match_type)

        filters = base_filters(warehouse_id: warehouse_id, match_type: match_type) + SSN_FILTERS
        new(
          match_type: match_type,
          field_expression: %(clients."SSN"),
          field_alias: 'ssn',
          filters: filters,
          include_value_in_results: true,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
      end

      def self.for_name_matches(match_type:, warehouse_id:, destination_data_source_ids: nil, unprocessed_ids: nil)
        ensure_match_type!(match_type)

        filters = base_filters(warehouse_id: warehouse_id, match_type: match_type) + NAME_PRESENCE_FILTERS
        new(
          match_type: match_type,
          field_expression: NORMALIZED_NAME_SQL,
          field_alias: 'normalized_name',
          filters: filters,
          include_value_in_results: false,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
      end

      def self.for_dob_matches(match_type:, warehouse_id:, destination_data_source_ids: nil, unprocessed_ids: nil)
        ensure_match_type!(match_type)

        filters = base_filters(warehouse_id: warehouse_id, match_type: match_type) + DOB_FILTERS
        new(
          match_type: match_type,
          field_expression: %(clients."DOB"),
          field_alias: 'dob',
          filters: filters,
          include_value_in_results: false,
          destination_data_source_ids: destination_data_source_ids,
          unprocessed_ids: unprocessed_ids,
        )
      end

      def self.base_filters(warehouse_id:, match_type:)
        filters = [%(clients."DateDeleted" IS NULL)]
        filters << %(clients.data_source_id != #{warehouse_id}) if match_type == :existing
        filters
      end
      private_class_method :base_filters

      def self.ensure_match_type!(match_type)
        return if MATCH_TYPES.include?(match_type)

        raise ArgumentError, "Unsupported match_type: #{match_type.inspect}"
      end
      private_class_method :ensure_match_type!

      def initialize(match_type:, field_expression:, field_alias:, filters:, include_value_in_results:, destination_data_source_ids: nil, unprocessed_ids: nil)
        @match_type = match_type
        @field_expression = field_expression
        @field_alias = field_alias
        @filters = filters
        @include_value_in_results = include_value_in_results
        @destination_data_source_ids = sanitize_ids(destination_data_source_ids)
        @unprocessed_ids = sanitize_ids(unprocessed_ids)
      end

      def to_sql
        match_type == :existing ? existing_sql : unprocessed_sql
      end

      # Executes the query and returns processed ID pairs
      # @param validate_ssn [Boolean] Whether to validate SSNs using HudHelper (only applies if SSN is in results)
      # @return [Array<Array<Integer>>] Array of ID pairs
      def execute(validate_ssn: false)
        results = GrdaWarehouse::Hud::Client.connection.execute(to_sql)

        # Filter SSNs if validation requested and SSN is in results
        results = results.select { |r| ::HudHelper.util.valid_social?(r['ssn']) } if validate_ssn && include_value_in_results && field_alias == 'ssn'

        # Map to ID pairs based on match type
        case match_type
        when :existing
          results.map { |r| [r['destination_one_id'], r['destination_two_id']] }.uniq
        when :unprocessed
          results.map { |r| [r['destination_client_id'], r['source_client_id']] }.uniq
        end
      end

      private

      attr_reader :match_type, :field_expression, :field_alias, :filters, :include_value_in_results,
                  :destination_data_source_ids, :unprocessed_ids

      # Space-efficient approach: Groups all matching clients by field value into arrays,
      # then generates unique pairs using array indices. This avoids materializing
      # the full cartesian product (N² temporary rows) produced by self-joins.
      def existing_sql
        <<-SQL
          WITH grouped_matches AS (
            SELECT
              #{field_expression} AS #{field_alias},
              array_agg(DISTINCT warehouse_clients.destination_id ORDER BY warehouse_clients.destination_id) AS destination_ids
            #{existing_from_clause}
            GROUP BY #{field_alias}
            HAVING COUNT(DISTINCT warehouse_clients.destination_id) > 1
          )
          SELECT
            destination_ids[idx_one] AS destination_one_id,
            destination_ids[idx_two] AS destination_two_id#{value_projection}
          FROM grouped_matches
          CROSS JOIN LATERAL (
            SELECT idx_one, idx_two
            FROM generate_subscripts(destination_ids, 1) AS idx_one
            JOIN generate_subscripts(destination_ids, 1) AS idx_two ON idx_one < idx_two
          ) AS destination_pairs
        SQL
      end

      def existing_from_clause
        <<-SQL
          FROM "Client" AS clients
          INNER JOIN warehouse_clients ON clients.id = warehouse_clients.source_id
          WHERE #{filters.join("\n            AND ")}
        SQL
      end

      def unprocessed_sql
        destination_ids_sql = destination_data_source_ids&.join(', ')
        unprocessed_ids_sql = unprocessed_ids&.join(', ')

        raise ArgumentError, 'destination_data_source_ids must be provided for unprocessed queries' if destination_ids_sql.blank?
        raise ArgumentError, 'unprocessed_ids must be provided for unprocessed queries' if unprocessed_ids_sql.blank?

        <<-SQL
          WITH destination_matches AS (
            SELECT
              #{field_expression} AS #{field_alias},
              array_agg(DISTINCT clients.id ORDER BY clients.id) AS destination_ids
            #{unprocessed_from_clause}
              AND clients.data_source_id IN (#{destination_ids_sql})
            GROUP BY #{field_alias}
          ),
          source_matches AS (
            SELECT
              clients.id AS source_client_id,
              #{field_expression} AS #{field_alias}
            #{unprocessed_from_clause}
              AND clients.id IN (#{unprocessed_ids_sql})
          )
          SELECT
            destination_ids[idx] AS destination_client_id,
            source_client_id#{value_projection}
          FROM destination_matches
          JOIN source_matches USING (#{field_alias})
          CROSS JOIN LATERAL generate_subscripts(destination_ids, 1) AS idx
          WHERE destination_ids[idx] != source_client_id
        SQL
      end

      def unprocessed_from_clause
        <<-SQL
          FROM "Client" AS clients
          WHERE #{filters.join("\n            AND ")}
        SQL
      end

      def value_projection
        include_value_in_results ? ",\n            #{field_alias}" : ''
      end

      def sanitize_ids(ids)
        return [] if ids.blank?

        ids.map(&:to_i)
      end
    end
  end
end
