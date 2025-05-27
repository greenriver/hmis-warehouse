# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
module GrdaWarehouse::Tasks
  class IdentifyDuplicates
    include ArelHelper
    include NotifierConfig
    include Memery
    MAX_SOURCE_CLIENTS = 50

    def initialize(run_post_processing: true)
      setup_notifier('IdentifyDuplicates')
      @run_post_processing = run_post_processing
    end

    def run!
      # with_advisory lock with a timeout returns false if the lock was not acquired
      return if GrdaWarehouseBase.with_advisory_lock('identify_duplicates', timeout_seconds: 0) { identify_duplicates }

      msg = 'Skipping identify duplicates, all ready running.'
      Rails.logger.warn msg
      @notifier.ping(msg) if @send_notifications
    end

    # Deduplicates client records by:
    # 1. Restoring any previously deleted destination clients still referenced.
    # 2. Loading all unprocessed clients (not yet linked in warehouse_clients).
    # 3. For each unprocessed client:
    #    - If a match is found among existing destinations, update the destination and link it.
    #    - If no match, create a new destination client and link it.
    # 4. Invalidates service history for affected clients.
    # 5. Finalizes (accepts) any exact matches that were previously proposed
    # 6. Logs the deduplication run.
    def identify_duplicates
      restore_previously_deleted_destinations

      Rails.logger.info 'Loading unprocessed clients'
      started_at = DateTime.now

      @dnd_warehouse_data_source = GrdaWarehouse::DataSource.destination.first
      return unless @dnd_warehouse_data_source

      # compare unprocessed to destinations, looking for a match
      # If we don't find a match:
      #   create a new destination (based on the unprocessed client)
      #   add a associated record to WarehouseClient
      # If we do find a match:
      #   create the associated WarehouseClient

      unprocessed_count = unprocessed.count
      Rails.logger.info "Matching #{unprocessed_count} unprocessed clients"
      matched = 0
      new_created = 0
      # ===========================================================================
      # IMPORTANT: This is where destination clients are created and updated
      # The system creates new destination clients for unprocessed source clients
      # and updates existing destination clients with new SSN/DOB information
      # ===========================================================================

      # Find all potential matches
      more_than_one_match = find_merge_candidates_for_unprocessed.sort
      more_than_one_match = more_than_one_match.map(&:reverse).to_h

      # At this point more_than_one_match contains pairs of source client id and destination client id where the
      # source client should be merged into the destination client.
      # If the source client does not exist in any of the pairs, a new destination client should be created for it.
      destination_clients_by_id = GrdaWarehouse::Hud::Client.destination.where(id: more_than_one_match.values).index_by(&:id)

      unprocessed.find_in_batches do |batch|
        matched_ids = []
        destination_client_updates = []
        new_destination_clients = []
        new_warehouse_clients = {}
        source_client_ids_with_new_destination_clients = []

        batch.each do |client|
          destination_client = nil
          if more_than_one_match.key?(client.id)
            matched += 1
            # Pick the first matching pair that includes this unmatched client
            # Scenarios:
            # 1. Simple: 1 destination, 1 unmatched source client with matching PII (will find the one pair)
            # 2. 2 destinations share one of three PII fields, 1 source client that matches one of the two destinations (will find the matching destination)
            # 3. 2 with identical PII, previously split to indicate they are not the same person, 1 source client with matching PII (will create a single pair with one of the destination clients).  This is ok, because we know the destination clients are not the same, but we don't know which the source should be connected to, so just pick one (we're sorting above to always pick the same one)
            destination_id = more_than_one_match[client.id]
            matched_ids << destination_id
            new_warehouse_clients[client.id] = GrdaWarehouse::WarehouseClient.new(
              id_in_source: client.personal_id,
              source_id: client.id,
              destination_id: destination_id,
              data_source_id: client.data_source_id,
            )

            destination_client = destination_clients_by_id[destination_id]
            # Set SSN & DOB if we have it in the incoming client, but not in the destination
            destination_client.dob ||= client.dob if client&.dob.present?
            destination_client.ssn ||= client.ssn if client&.ssn.present?
            destination_client.first_name ||= client.first_name if client&.first_name.present?
            destination_client.last_name ||= client.last_name if client&.last_name.present?

            # set non-nullable fields, these aren't used because of the column limitation on import
            # but Postgres complains if they aren't there
            destination_client.personal_id = client.personal_id
            destination_client.data_source_id = @dnd_warehouse_data_source.id
            destination_client_updates << destination_client if destination_client.changed?
          else
            new_created += 1
            destination_client = client.dup
            destination_client.data_source_id = @dnd_warehouse_data_source.id
            destination_client.apply_housing_release_status
            new_destination_clients << destination_client
            source_client_ids_with_new_destination_clients << client.id

            new_warehouse_clients[client.id] = GrdaWarehouse::WarehouseClient.new(
              id_in_source: client.personal_id,
              source_id: client.id,
              destination_id: nil, # Destination client hasn't been saved, so has no id yet
              data_source_id: client.data_source_id,
            )
          end
        end
        # Persist any updates to destination clients
        GrdaWarehouse::Hud::Client.import(
          destination_client_updates.uniq { |m| m[:id] }, # ensure no duplicate rows
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:SSN, :DOB, :FirstName, :LastName],
          },
          validate: false,
        )
        # Create new destination clients
        new_destination_ids = GrdaWarehouse::Hud::Client.import(new_destination_clients).ids

        # Update warehouse clients with new destination IDs
        source_client_ids_with_new_destination_clients.zip(new_destination_ids).each do |source_id, destination_id|
          new_warehouse_clients[source_id][:destination_id] = destination_id
        end
        GrdaWarehouse::WarehouseClient.import(new_warehouse_clients.values)
        GrdaWarehouse::Hud::Client.where(id: matched_ids).find_each(&:invalidate_service_history)
      end
      # Cleanup any proposed matches that might have been affected
      GrdaWarehouse::ClientMatch.accept_exact_matches!
      # Record completed run
      completed_at = DateTime.now
      GrdaWarehouse::IdentifyDuplicatesLog.create!(
        started_at: started_at,
        completed_at: completed_at,
        to_match: unprocessed_count,
        matched: matched,
        new_created: new_created,
      )
      Rails.logger.info 'Done'
    end

    # look at all existing records for duplicates and merge destination clients
    # We'll do as much of this in the database as possible for performance and memory management
    # Matches and merges existing destination clients that are determined to be duplicates
    # This method:
    # 1. Finds merge candidates using find_merge_candidates_for_match_existing
    # 2. Processes candidates in batches of 500
    # 3. For each batch, attempts to merge source clients (actually warehouse destination clients) into destination clients
    # 4. Marks any previous candidate matches as accepted
    # 5. Optionally runs post-processing to update service history
    # @note This is a destructive operation that will merge client records
    # @param [Boolean] @run_post_processing Whether to run service history updates after merging
    # @return [void]
    def match_existing!
      user = User.setup_system_user
      if GrdaWarehouse::Config.get(:enable_auto_deduplication)
        Rails.logger.info '=== Starting match_existing! ==='
      else
        Rails.logger.info '=== match_existing! not running, auto deduplication is disabled ==='
        return
      end
      # candidates now contains a hash keyed on client ids with arrays of destination client ids that will be
      # used as the source for merges into the key client id.
      # At this point the `key => ids` combinations have been grouped so any merges that would have
      # required multiple iterations are all in the array associated with the destination client,
      # all merges have been checked to confirm they won't exceed the max allowable source clients, and if
      # they would have exceeded the limit, a new group has been added
      candidates = find_merge_candidates_for_match_existing
      Rails.logger.info "Found #{candidates.size} merge candidates"

      candidates.each_slice(500) do |batch|
        client_lookups = GrdaWarehouse::Hud::Client.where(id: batch.flatten).index_by(&:id)
        batch.each do |destination_id, source_ids|
          source_ids.each do |source_id|
            destination = client_lookups[destination_id]
            source = client_lookups[source_id]
            next unless destination.present? && source.present?

            # If this pair was previously a candidate match, mark it as accepted
            check_and_mark_previous_candidate_matches(source_id, destination_id)

            begin
              Rails.logger.info "Attempting merge of #{source_id} into #{destination_id}"
              # merge_from must be called on a destination client, "source" can be a destination or array of source clients
              # This will log an error if the destination does not have at least one source client
              destination.merge_from(source, reviewed_by: user, reviewed_at: DateTime.current, cleanup: false)
            rescue Exception => e
              Rails.logger.error "Merge failed: #{e.message}\n#{e.backtrace.join("\n")}"
              Sentry.capture_exception_with_info(
                e,
                info: {
                  source_id: source.id,
                  destination_id: destination.id,
                },
              )
            end
          end
        end
        ClientCleanupJob.set(priority: 6).perform_later(batch.flatten)
      end
      Rails.logger.info '=== Completed match_existing! ==='
      return unless @run_post_processing

      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
    end

    memoize private def previous_candidate_matches
      GrdaWarehouse::ClientMatch.processed_or_candidate.pluck(:source_client_id, :destination_client_id).to_set
    end

    private def mark_as_accepted(source_id, destination_id)
      GrdaWarehouse::ClientMatch.processed_or_candidate.where(
        source_client_id: source_id,
        destination_client_id: destination_id,
      ).find_each do |client_match|
        client_match.flag_as(status: 'accepted')
      end
    end

    private def check_and_mark_previous_candidate_matches(source_id, destination_id)
      [
        [source_id, destination_id],
        [destination_id, source_id],
      ].each do |pair|
        if previous_candidate_matches.include?(pair)
          Rails.logger.info "Found previous candidate match: source=#{pair.first} destination=#{pair.last}"
          mark_as_accepted(pair.first, pair.last)
        end
      end
    end

    # Finds pairs of destination client IDs with exact SSN matches among source clients.
    # Uses a CTE to efficiently compare all source clients and returns pairs of destination IDs
    # where the SSN is valid and matches.
    #
    # @return [Array<Array<Integer>>] Array of [destination_one_id, destination_two_id] pairs
    def exact_ssn_matches
      # Use a CTE to find potential matches based on multiple criteria
      # This keeps the heavy lifting in the database
      limits = <<-SQL
        "Client" as clients
        inner join warehouse_clients on clients.id = warehouse_clients.source_id
        where clients."DateDeleted" is NULL
        and clients.data_source_id != #{GrdaWarehouse::DataSource.warehouse_id} -- not a destination client
        -- ignore blanks and some obvious known ssns
        and clients."SSN" is not null
        and clients."SSN" != ''
        and clients."SSN" != '000000000'
        and clients."SSN" != '111111111'
        and LEFT(clients."SSN", 3) != '999'
        and LEFT(clients."SSN", 1) != 'x'
        and LEFT(clients."SSN", 1) != 'X'
        and RIGHT(clients."SSN", 1) != 'x'
        and RIGHT(clients."SSN", 1) != 'X'
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one as (
          SELECT warehouse_clients.destination_id as destination_one_id,
            clients."SSN" as destination_one_ssn
            from #{limits}
          ),
          client_two as (
          SELECT warehouse_clients.destination_id as destination_two_id,
            clients."SSN" as destination_two_ssn
            from #{limits}
          )

          SELECT DISTINCT
              destination_one_id,
              destination_two_id,
              destination_one_ssn as ssn,
              destination_two_ssn as ssn2
            FROM client_one
            JOIN client_two ON (
              -- Match on SSN if both have it
              destination_one_ssn = destination_two_ssn
            )
            WHERE destination_one_id < destination_two_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.
        select { |r| ::HudUtility2024.valid_social?(r['ssn']) }.
        map { |r| [r['destination_one_id'], r['destination_two_id']] }.
        uniq
    end

    # Finds pairs of destination client IDs with exact normalized name matches among source clients.
    # Uses a CTE to compare all source clients and returns pairs of destination IDs
    # where the normalized (lowercased, stripped, unaccented) first and last names match.
    #
    # @return [Array<Array<Integer>>] Array of [destination_one_id, destination_two_id] pairs
    def exact_name_matches
      limits = <<-SQL
        "Client" as clients
        inner join warehouse_clients on clients.id = warehouse_clients.source_id
        where clients."DateDeleted" is NULL
        and clients.data_source_id != #{GrdaWarehouse::DataSource.warehouse_id} -- not a destination client
        and (clients."FirstName" is not null and trim(clients."FirstName") != ''
        and clients."LastName" is not null and trim(clients."LastName") != '')
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_name as (
        SELECT warehouse_clients.destination_id as destination_one_id,
          concat(regexp_replace(lower(trim(unaccent(clients."FirstName"))), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(unaccent(clients."LastName"))), '[^a-z0-9]', '', 'g')) as destination_one_name
          from #{limits}
        ),
        client_two_name as (
        SELECT warehouse_clients.destination_id as destination_two_id,
          concat(regexp_replace(lower(trim(unaccent(clients."FirstName"))), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(unaccent(clients."LastName"))), '[^a-z0-9]', '', 'g')) as destination_two_name
          from #{limits}
        )

        SELECT DISTINCT
          destination_one_id,
          destination_two_id
        FROM client_one_name
        JOIN client_two_name ON (
          -- Match on normalized name if both have it
          destination_one_name = destination_two_name
        )
        WHERE destination_one_id < destination_two_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.map { |r| [r['destination_one_id'], r['destination_two_id']] }
    end

    # Finds pairs of destination client IDs with exact date of birth matches among source clients.
    # Uses a CTE to compare all source clients and returns pairs of destination IDs
    # where the DOB is present, after 1920, and matches.
    #
    # @return [Array<Array<Integer>>] Array of [destination_one_id, destination_two_id] pairs
    def exact_dob_matches
      limits = <<-SQL
        "Client" as clients
          inner join warehouse_clients on clients.id = warehouse_clients.source_id
          where clients."DateDeleted" is NULL
          and clients.data_source_id != #{GrdaWarehouse::DataSource.warehouse_id} -- not a destination client
          and clients."DOB" is not null
          and date_part('year', clients."DOB") > 1920
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_dob as (
          SELECT warehouse_clients.destination_id as destination_one_id,
            clients."DOB" as destination_one_dob
            from #{limits}
        ),
        client_two_dob as (
          SELECT warehouse_clients.destination_id as destination_two_id,
            clients."DOB" as destination_two_dob
            from #{limits}
        )

        SELECT DISTINCT
          destination_one_id,
          destination_two_id
        FROM client_one_dob
        JOIN client_two_dob ON (
          -- Match on DOB if both have it
          destination_one_dob = destination_two_dob
        )
        WHERE destination_one_id < destination_two_id  -- Avoid duplicate pairs
      SQL
      results.map { |r| [r['destination_one_id'], r['destination_two_id']] }
    end

    # Finds pairs of destination and unprocessed source client IDs with exact SSN matches.
    # Expands the search to any client, even those without a warehouse_client record.
    # Only returns pairs where the SSN is valid and matches.
    #
    # @return [Array<Array<Integer>>] Array of [destination_client_id, source_client_id] pairs
    def exact_ssn_matches_for_unprocessed
      # Use a CTE to find potential matches based on multiple criteria
      # This keeps the heavy lifting in the database
      limits = <<-SQL
        where clients."DateDeleted" is NULL
        -- ignore blanks and some obvious known ssns
        and clients."SSN" is not null
        and clients."SSN" != ''
        and clients."SSN" != '000000000'
        and clients."SSN" != '111111111'
        and LEFT(clients."SSN", 3) != '999'
        and LEFT(clients."SSN", 1) != 'x'
        and LEFT(clients."SSN", 1) != 'X'
        and RIGHT(clients."SSN", 1) != 'x'
        and RIGHT(clients."SSN", 1) != 'X'
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one as (
          SELECT clients.id as destination_client_id,
            clients."SSN" as destination_client_ssn
            from "Client" as clients
            #{limits}
            and clients.data_source_id in (#{GrdaWarehouse::DataSource.destination_data_source_ids.join(',')})
          ),
          client_two as (
          SELECT clients.id as source_client_id,
            clients."SSN" as source_client_ssn
            from "Client" as clients
            #{limits}
            and clients.id in (#{unprocessed_ids.join(',')})
          )

          SELECT DISTINCT
              destination_client_id,
              source_client_id,
              destination_client_ssn as ssn,
              source_client_ssn as ssn2
            FROM client_one
            JOIN client_two ON (
              -- Match on SSN if both have it
              destination_client_ssn = source_client_ssn
            )
            WHERE destination_client_id != source_client_id
      SQL
      # return an array of ID pairs
      results.
        select { |r| ::HudUtility2024.valid_social?(r['ssn']) }.
        map { |r| [r['destination_client_id'], r['source_client_id']] }.
        uniq
    end

    # Finds pairs of destination and unprocessed source client IDs with exact normalized name matches.
    # Expands the search to any client, even those without a warehouse_client record.
    #
    # @return [Array<Array<Integer>>] Array of [destination_client_id, source_client_id] pairs
    def exact_name_matches_for_unprocessed
      limits = <<-SQL
        where clients."DateDeleted" is NULL
        and (clients."FirstName" is not null and trim(clients."FirstName") != ''
        and clients."LastName" is not null and trim(clients."LastName") != '')
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_name as (
        SELECT clients.id as destination_client_id,
          concat(regexp_replace(lower(trim(unaccent(clients."FirstName"))), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(unaccent(clients."LastName"))), '[^a-z0-9]', '', 'g')) as destination_client_name
          from "Client" as clients
          #{limits}
          and clients.data_source_id in (#{GrdaWarehouse::DataSource.destination_data_source_ids.join(',')})
        ),
        client_two_name as (
        SELECT clients.id as source_client_id,
          concat(regexp_replace(lower(trim(unaccent(clients."FirstName"))), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(unaccent(clients."LastName"))), '[^a-z0-9]', '', 'g')) as source_client_name
          from "Client" as clients
          #{limits}
          and clients.id in (#{unprocessed_ids.join(',')})
        )

        SELECT DISTINCT
          destination_client_id,
          source_client_id
        FROM client_one_name
        JOIN client_two_name ON (
          -- Match on normalized name if both have it
          destination_client_name = source_client_name
        )
        WHERE destination_client_id != source_client_id
      SQL
      # return an array of ID pairs
      results.map { |r| [r['destination_client_id'], r['source_client_id']] }
    end

    # Finds pairs of destination and unprocessed source client IDs with exact date of birth matches.
    # Expands the search to any client, even those without a warehouse_client record.
    #
    # @return [Array<Array<Integer>>] Array of [destination_client_id, source_client_id] pairs
    def exact_dob_matches_for_unprocessed
      limits = <<-SQL
        where clients."DateDeleted" is NULL
        and clients."DOB" is not null
        and date_part('year', clients."DOB") > 1920
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_dob as (
          SELECT clients.id as destination_client_id,
            clients."DOB" as destination_client_dob
            from
            "Client" as clients
            #{limits}
            and clients.data_source_id in (#{GrdaWarehouse::DataSource.destination_data_source_ids.join(',')})
        ),
        client_two_dob as (
          SELECT clients.id as source_client_id,
            clients."DOB" as source_client_dob
            from
            "Client" as clients
            #{limits}
            and clients.id in (#{unprocessed_ids.join(',')})
        )

        SELECT DISTINCT
          destination_client_id,
          source_client_id
        FROM client_one_dob
        JOIN client_two_dob ON (
          -- Match on DOB if both have it
          destination_client_dob = source_client_dob
        )
        WHERE destination_client_id != source_client_id
      SQL
      results.map { |r| [r['destination_client_id'], r['source_client_id']] }
    end

    # Find potential client merge candidates by looking for matches across multiple criteria
    # @return [Hash] A set of client ID pairs that are candidates for merging
    # @note Only returns matches if auto deduplication is enabled in config
    # @note Filters out any previously split client pairs
    # @note Checks source client counts to avoid exceeding limits
    private def find_merge_candidates_for_match_existing
      # Never return obvious matches if auto deduplication is disabled
      unless GrdaWarehouse::Config.get(:enable_auto_deduplication)
        Rails.logger.info 'Auto deduplication disabled, returning empty set'
        return {}
      end

      # Find all potential matches
      matches = {}
      exact_ssn_matches.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end
      exact_name_matches.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end
      exact_dob_matches.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end
      more_than_one_match = matches.select { |_, v| v > 1 }

      # Get split history
      all_splits = GrdaWarehouse::ClientSplitHistory.pluck(:split_from, :split_into)
      Rails.logger.info "Found #{all_splits.size} split history records: #{all_splits.inspect}"

      # Filter more_than_one_match removing any that were split previously
      all_splits.each do |row|
        sorted_row = row.sort
        next unless more_than_one_match.key?(sorted_row)

        Rails.logger.info "Removing previously split pair: #{sorted_row.inspect}"
        more_than_one_match.delete(sorted_row)
      end
      candidates = group_merge_chains(more_than_one_match)

      source_client_counts = GrdaWarehouse::WarehouseClient.group(:destination_id).count
      split_chains_on_max_source(candidates: candidates, counts: source_client_counts)
    end

    # Find potential client merge candidates by looking for matches across multiple criteria
    # @return [Array<Array<Integer>>] Array of [destination_id, source_id] pairs that are candidates for merging
    # @note Only returns matches if auto deduplication is enabled in config
    private def find_merge_candidates_for_unprocessed
      # Never return obvious matches if auto deduplication is disabled
      unless GrdaWarehouse::Config.get(:enable_auto_deduplication)
        Rails.logger.info 'Auto deduplication disabled, returning empty set'
        return []
      end

      # Find all potential matches
      matches = {}
      return matches if unprocessed_ids.empty?

      exact_ssn_matches_for_unprocessed.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end
      exact_name_matches_for_unprocessed.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end
      exact_dob_matches_for_unprocessed.each do |id_pair|
        matches[id_pair] ||= 0
        matches[id_pair] += 1
      end

      matches.select { |_, v| v > 1 }.keys
    end

    # Check if a client pair should be rejected based on source client counts
    # @param destination_id [Integer] The ID of the destination client
    # @param source_id [Integer] The ID of the source client
    # @param counts [Hash] Hash mapping destination client IDs to their source client counts
    # @return [Boolean] True if the client pair should be rejected, false otherwise
    private def will_exceed_source_counts?(destination_id:, source_id:, counts:)
      destination_count = counts[destination_id].to_i
      source_count = counts[source_id].to_i
      # If adding one more source client would exceed the limit, reject the merge
      value = destination_count + source_count > MAX_SOURCE_CLIENTS

      # Prevent ever merging 50 clients in production
      raise "will_exceed_source_counts? #{destination_id} #{source_id} #{destination_count} #{source_count} #{value}" if value && Rails.env.production?

      value
    end

    # Groups candidate merges into chains to process them efficiently
    # @param candidates [Hash<Array<Integer>, Object>] Hash mapping pairs of client IDs to merge data
    # @return [Hash<Integer, Array<Integer>>] Hash mapping root client IDs to arrays of child client IDs to merge
    private def group_merge_chains(candidates)
      parent = {}
      candidates.each_key { |(a, b)| parent[b] = a }

      groups = Hash.new { |h, k| h[k] = [] }
      parent.each_key do |child|
        root = find_root(child, parent)
        groups[root] << child unless root == child
      end

      groups.each { |_, arr| arr.uniq! }
      groups
    end

    private def find_root(id, parent)
      visited = Set.new
      current = id
      while parent[current] && !visited.include?(current)
        visited.add(current)
        current = parent[current]
      end
      # If we hit a cycle, choose the lowest ID in the cycle as the root
      if visited.include?(current)
        visited.add(current)
        visited.min
      else
        current
      end
    end

    # Splits merge chains that would exceed the maximum allowed source clients per destination
    # @param candidates [Hash<Integer, Array<Integer>>] Hash mapping root client IDs to arrays of child client IDs to merge
    # @param counts [Hash<Integer, Integer>] Hash mapping client IDs to their current source client counts
    # @return [Hash<Integer, Array<Integer>>] New hash of merge chains split to not exceed max source clients
    private def split_chains_on_max_source(candidates:, counts:)
      new_chains = {}

      candidates.each do |root, chain|
        current_root = root
        current_chain = []

        chain.each do |source_id|
          if will_exceed_source_counts?(destination_id: current_root, source_id: source_id, counts: counts)
            # Alert if this happens in production so we can investigate
            Sentry.capture_message("IdentifyDuplicates: Reached max source clients when merging: #{source_id} with #{current_root}, you should probably investigate") if Rails.env.production?
            # Save the current chain if not empty
            new_chains[current_root] = current_chain unless current_chain.empty?
            # Start a new chain
            current_root = source_id
            current_chain = []
          end
          # note that we are going to have these source clients even though the merge hasn't happened
          increment_source_count(destination_id: current_root, source_id: source_id, counts: counts)
          # Add the client to the current chain, but only if it's not the root.
          # If we end up with an empty chain, that's fine, the source_ids are actually destination
          # client ids.  An empty chain just means we won't be merging into that client at this time
          current_chain << source_id unless current_root == source_id
        end

        # Save the last chain
        new_chains[current_root] = current_chain unless current_chain.empty?
      end

      new_chains
    end

    private def increment_source_count(destination_id:, source_id:, counts:)
      counts[destination_id] ||= 0
      counts[destination_id] += counts[source_id].to_i
    end

    # Find any destination clients that have been marked deleted where the source client is not deleted
    # and a warehouse client record exists.  Un-delete them and queue them for re-processing
    private def restore_previously_deleted_destinations
      destination_client_ids = client_destinations.pluck(:id)
      known_warehouse_destination_client_ids = GrdaWarehouse::WarehouseClient.
        where(source_id: GrdaWarehouse::Hud::Client.source.select(:id)).
        distinct.
        pluck(:destination_id)
      deleted_destination_ids = known_warehouse_destination_client_ids - destination_client_ids
      return unless deleted_destination_ids.any?

      @notifier.ping("Restoring #{deleted_destination_ids.count} destination clients and invalidating their data")
      deleted_destination_ids.each_slice(5_000) do |batch|
        client_destinations.only_deleted.where(id: batch).find_each(&:force_full_service_history_rebuild)
        client_destinations.only_deleted.where(id: batch).update_all(DateDeleted: nil)
      end
    end

    # figure out who doesn't yet have an entry in warehouse clients
    private def unprocessed
      GrdaWarehouse::Hud::Client.where(id: unprocessed_ids)
    end

    private def unprocessed_ids
      GrdaWarehouse::Hud::Client.source.pluck(:id) - GrdaWarehouse::WarehouseClient.pluck(:source_id)
    end

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    private def client_destinations
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
