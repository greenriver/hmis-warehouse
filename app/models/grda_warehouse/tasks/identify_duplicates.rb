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
      @logger = Rails.logger
    end

    def run!
      # with_advisory lock with a timeout returns false if the lock was not acquired
      return if GrdaWarehouseBase.with_advisory_lock('identify_duplicates', timeout_seconds: 0) { identify_duplicates }

      msg = 'Skipping identify duplicates, all ready running.'
      Rails.logger.warn msg
      @notifier.ping(msg) if @send_notifications
    end

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
      Rails.logger.info 'Matching #unprocessed_count} unprocessed clients'
      matched = 0
      new_created = 0

      # Find all potential matches
      matches = {}
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
      more_than_one_match = matches.select { |_, v| v > 1 }.keys
      found_ids = more_than_one_match.flatten.uniq.to_set

      # At this point more_than_one_match contains pairs of destination client id and source client id where the
      # source client should be merged into the destination client.
      # If the source client does not exist in any of the pairs, a new destination client should be created for it.
      destination_clients_by_id = GrdaWarehouse::Hud::Client.where(id: found_ids.to_a).index_by(&:id)
      unprocessed.find_in_batches do |batch|
        matched_ids = []
        destination_client_updates = []
        new_destination_clients = []
        new_warehouse_clients = {}
        source_client_ids_with_new_destination_clients = []
        destination_client = nil

        batch.each do |client|
          if found_ids.include?(client.id)
            matched_pair = more_than_one_match.find { |pair| pair.include?(client.id) }
            destination_id = (matched_pair - [client.id]).first # We don't know the order of the pair
            matched_ids << destination_id
            new_warehouse_clients[client.id] = GrdaWarehouse::WarehouseClient.new(
              id_in_source: client.personal_id,
              source_id: client.id,
              destination_id: destination_id,
              data_source_id: client.data_source_id,
            )

            destination_client = destination_clients_by_id[destination_id]
            # Set SSN & DOB if we have it in the incoming client, but not in the destination
            destination_client.dob = client.dob if client.dob.present? && destination_client.dob.blank?
            destination_client.ssn = client.ssn if client.ssn.present? && destination_client.ssn.blank?
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

          # set non-nullable fields, these aren't used because of the column limitation on import
          # but Postgres complains if they aren't there
          destination_client.personal_id = client.personal_id
          destination_client.data_source_id = @dnd_warehouse_data_source.id
          destination_client_updates << destination_client
        end
        # Persist any updates to destination clients
        GrdaWarehouse::Hud::Client.import(
          destination_client_updates.uniq { |m| m[:id] }, # ensure no duplicate rows
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:SSN, :DOB],
          },
          validate: false,
        )

        # Create new destination clients
        new_destination_ids = GrdaWarehouse::Hud::Client.import(new_destination_clients.uniq).ids

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
      GrdaWarehouse::IdentifyDuplicatesLog.create(
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
    # 1. Finds merge candidates using find_merge_candidates
    # 2. Processes candidates in batches of 500
    # 3. For each batch, attempts to merge source clients (actually warehouse destination clients) into destination clients
    # 4. Marks any previous candidate matches as accepted
    # 5. Optionally runs post-processing to update service history
    # @note This is a destructive operation that will merge client records
    # @param [Boolean] @run_post_processing Whether to run service history updates after merging
    # @return [void]
    def match_existing!
      user = User.setup_system_user
      @logger.info '=== Starting match_existing! ==='

      # candidates now contains a hash keyed on client ids with arrays of destination client ids that will be
      # used as the source for merges into the key client id.
      # At this point the `key => ids` combinations have been grouped so any merges that would have
      # required multiple iterations are all in the array associated with the destination client,
      # all merges have been checked to confirm they won't exceed the max allowable source clients, and if
      # they would have exceeded the limit, a new group has been added
      candidates = find_merge_candidates
      @logger.info "Found #{candidates.size} merge candidates"

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
              @logger.info "Attempting merge of #{source_id} into #{destination_id}"
              # merge_from must be called on a destination client, "source" can be a destination or array of source clients
              # This will log an error if the destination does not have at least one source client
              destination.merge_from(source, reviewed_by: user, reviewed_at: DateTime.current)
            rescue Exception => e
              @logger.error "Merge failed: #{e.message}\n#{e.backtrace.join("\n")}"
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
      end
      @logger.info '=== Completed match_existing! ==='
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
          @logger.info "Found previous candidate match: source=#{pair.first} destination=#{pair.last}"
          mark_as_accepted(pair.first, pair.last)
        end
      end
    end

    # Use a CTE to find potential matches based on multiple criteria
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
          SELECT warehouse_clients.destination_id as client_one_id,
            clients."SSN" as client_one_ssn
            from #{limits}
          ),
          client_two as (
          SELECT warehouse_clients.destination_id as client_two_id,
            clients."SSN" as client_two_ssn
            from #{limits}
          )

          SELECT DISTINCT
              client_one_id,
              client_two_id,
              client_one_ssn as ssn,
              client_two_ssn as ssn2
            FROM client_one
            JOIN client_two ON (
              -- Match on SSN if both have it
              client_one_ssn = client_two_ssn
            )
            WHERE client_one_id < client_two_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.
        select { |r| ::HudUtility2024.valid_social?(r['ssn']) }.
        map { |r| [r['client_one_id'], r['client_two_id']] }.
        uniq
    end

    def exact_name_matches
      limits = <<-SQL
        "Client" as clients
        inner join warehouse_clients on clients.id = warehouse_clients.source_id
        where clients."DateDeleted" is NULL
        and clients.data_source_id != #{GrdaWarehouse::DataSource.warehouse_id} -- not a destination client
        and (clients."FirstName" is not null and clients."FirstName" != ''
        or clients."LastName" is not null and clients."LastName" != '')
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_name as (
        SELECT warehouse_clients.destination_id as client_one_name_id,
          concat(regexp_replace(lower(trim(clients."FirstName")), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(clients."LastName")), '[^a-z0-9]', '', 'g')) as client_one_name_name
          from #{limits}
        ),
        client_two_name as (
        SELECT warehouse_clients.destination_id as client_two_name_id,
          concat(regexp_replace(lower(trim(clients."FirstName")), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(clients."LastName")), '[^a-z0-9]', '', 'g')) as client_two_name_name
          from #{limits}
        )

        SELECT DISTINCT
          client_one_name_id,
          client_two_name_id
        FROM client_one_name
        JOIN client_two_name ON (
          -- Match on normalized name if both have it
          client_one_name_name = client_two_name_name
        )
        WHERE client_one_name_id < client_two_name_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.map { |r| [r['client_one_name_id'], r['client_two_name_id']] }
    end

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
          SELECT warehouse_clients.destination_id as client_one_dob_id,
            clients."DOB" as client_one_dob_dob
            from #{limits}
        ),
        client_two_dob as (
          SELECT warehouse_clients.destination_id as client_two_dob_id,
            clients."DOB" as client_two_dob_dob
            from #{limits}
        )

        SELECT DISTINCT
          client_one_dob_id,
          client_two_dob_id
        FROM client_one_dob
        JOIN client_two_dob ON (
          -- Match on DOB if both have it
          client_one_dob_dob = client_two_dob_dob
        )
        WHERE client_one_dob_id < client_two_dob_id  -- Avoid duplicate pairs
      SQL
      results.map { |r| [r['client_one_dob_id'], r['client_two_dob_id']] }
    end

    # When looking to match unprocessed clients, we expand the search to any client, even if they do not have a warehouse_client record
    # NOTE: This may not be correct
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
          SELECT coalesce(warehouse_clients.destination_id, clients.id) as client_one_id,
            clients."SSN" as client_one_ssn
            from "Client" as clients
            left outer join warehouse_clients on (clients.id = warehouse_clients.source_id OR clients.id = warehouse_clients.destination_id)
            #{limits}
          ),
          client_two as (
          SELECT clients.id as client_two_id,
            clients."SSN" as client_two_ssn
            from "Client" as clients
            #{limits}
            and clients.id in (#{unprocessed.select(:id).to_sql})
          )

          SELECT DISTINCT
              client_one_id,
              client_two_id,
              client_one_ssn as ssn,
              client_two_ssn as ssn2
            FROM client_one
            JOIN client_two ON (
              -- Match on SSN if both have it
              client_one_ssn = client_two_ssn
            )
            WHERE client_one_id < client_two_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.
        select { |r| ::HudUtility2024.valid_social?(r['ssn']) }.
        map { |r| [r['client_one_id'], r['client_two_id']] }.
        uniq
    end

    def exact_name_matches_for_unprocessed
      limits = <<-SQL
        where clients."DateDeleted" is NULL
        and (clients."FirstName" is not null and clients."FirstName" != ''
        or clients."LastName" is not null and clients."LastName" != '')
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_name as (
        SELECT coalesce(warehouse_clients.destination_id, clients.id) as client_one_name_id,
          concat(regexp_replace(lower(trim(clients."FirstName")), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(clients."LastName")), '[^a-z0-9]', '', 'g')) as client_one_name_name
          from "Client" as clients
          left outer join warehouse_clients on (clients.id = warehouse_clients.source_id OR clients.id = warehouse_clients.destination_id)
          #{limits}
        ),
        client_two_name as (
        SELECT clients.id as client_two_name_id,
          concat(regexp_replace(lower(trim(clients."FirstName")), '[^a-z0-9]', '', 'g'), '_',
          regexp_replace(lower(trim(clients."LastName")), '[^a-z0-9]', '', 'g')) as client_two_name_name
          from "Client" as clients
          #{limits}
          and clients.id in (#{unprocessed.select(:id).to_sql})
        )

        SELECT DISTINCT
          client_one_name_id,
          client_two_name_id
        FROM client_one_name
        JOIN client_two_name ON (
          -- Match on normalized name if both have it
          client_one_name_name = client_two_name_name
        )
        WHERE client_one_name_id < client_two_name_id  -- Avoid duplicate pairs
      SQL
      # return an array of ID pairs
      results.map { |r| [r['client_one_name_id'], r['client_two_name_id']] }
    end

    def exact_dob_matches_for_unprocessed
      limits = <<-SQL
        where clients."DateDeleted" is NULL
        and clients."DOB" is not null
        and date_part('year', clients."DOB") > 1920
      SQL
      results = GrdaWarehouse::Hud::Client.connection.execute(<<-SQL)
        with client_one_dob as (
          SELECT coalesce(warehouse_clients.destination_id, clients.id) as client_one_dob_id,
            clients."DOB" as client_one_dob_dob
            from
            "Client" as clients
            left outer join warehouse_clients on (clients.id = warehouse_clients.source_id OR clients.id = warehouse_clients.destination_id)
            #{limits}
        ),
        client_two_dob as (
          SELECT clients.id as client_two_dob_id,
            clients."DOB" as client_two_dob_dob
            from
            "Client" as clients
            #{limits}
            and clients.id in (#{unprocessed.select(:id).to_sql})
        )

        SELECT DISTINCT
          client_one_dob_id,
          client_two_dob_id
        FROM client_one_dob
        JOIN client_two_dob ON (
          -- Match on DOB if both have it
          client_one_dob_dob = client_two_dob_dob
        )
        WHERE client_one_dob_id < client_two_dob_id  -- Avoid duplicate pairs
      SQL
      results.map { |r| [r['client_one_dob_id'], r['client_two_dob_id']] }
    end

    private def find_current_id_for(id)
      return merge_history.current_destination(id) unless client_destinations.where(id: id).exists?

      return id
    end

    private def merge_history
      @merge_history ||= GrdaWarehouse::ClientMergeHistory.new
    end

    # Find potential client merge candidates by looking for matches across multiple criteria
    # @return [Set] A set of client ID pairs that are candidates for merging
    # @note Only returns matches if auto deduplication is enabled in config
    # @note Filters out any previously split client pairs
    # @note Checks source client counts to avoid exceeding limits
    private def find_merge_candidates
      to_merge = Set.new

      # Never return obvious matches if auto deduplication is disabled
      unless GrdaWarehouse::Config.get(:enable_auto_deduplication)
        @logger.info 'Auto deduplication disabled, returning empty set'
        return to_merge
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
      @logger.info "Found #{all_splits.size} split history records: #{all_splits.inspect}"

      # Filter more_than_one_match removing any that were split previously
      all_splits.each do |row|
        sorted_row = row.sort
        next unless more_than_one_match.key?(sorted_row)

        @logger.info "Removing previously split pair: #{sorted_row.inspect}"
        more_than_one_match.delete(sorted_row)
      end
      candidates = group_merge_chains(more_than_one_match)

      source_client_counts = GrdaWarehouse::WarehouseClient.group(:destination_id).count
      split_chains_on_max_source(candidates: candidates, counts: source_client_counts)
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
      destination_count + source_count > MAX_SOURCE_CLIENTS
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
      id = parent[id] while parent[id]
      id
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
          current_chain << source_id
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
      GrdaWarehouse::Hud::Client.where(
        id: GrdaWarehouse::Hud::Client.source.pluck(:id) - GrdaWarehouse::WarehouseClient.pluck(:source_id),
      )
    end

    # Destination clients are limited to MAX_SOURCE_CLIENTS number of source clients. This is to prevent runaway duplicate merges.
    # This will return the ids of any destination clients that is at or beyond this threshold so they can be filtered out of future matching.
    # We are using unmatchable destinations here to more easily include destination clients who do not have a warehouse client record.
    # This should also be a smaller list than the full list of matchable destination ids.
    # NOTE: this is only calculated at the start of the run, if a client is merged more than once, it may exceed AX_SOURCE_CLIENTS
    private def unmatchable_destination_ids
      GrdaWarehouse::WarehouseClient.group(:destination_id).having('count(*) >= ?', MAX_SOURCE_CLIENTS).select(:destination_id)
    end

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    private def client_destinations
      GrdaWarehouse::Hud::Client.destination.where.not(id: unmatchable_destination_ids)
    end

    # Look for really clear matches (2 of the following 3 should be good):
    #   1. valid social and last 4 of social or entire social match
    #   2. birthdate matches
    #   3. perfect name matches
    private def check_for_obvious_match(client)
      # Never return obvious matches if auto deduplication is disabled
      return nil unless GrdaWarehouse::Config.get(:enable_auto_deduplication)

      ssn_matches = @dest_ssn_lookup.get_ids(ssn: client.SSN)
      birthdate_matches = @dest_dob_lookup.get_ids(dob: client.DOB)
      name_matches = @dest_name_lookup.get_ids(first_name: client.first_name, last_name: client.last_name)

      all_matches = ssn_matches + birthdate_matches + name_matches
      if Rails.env.development?
        personal_id_matches = check_personal_ids(client.PersonalID)
        all_matches += personal_id_matches
      end
      obvious_matches = all_matches.uniq.map { |i| i if all_matches.count(i) > 1 && !split?(client, i) }.compact

      return obvious_matches.first if obvious_matches.any?

      return nil
    end

    private def split?(client, candidate_id)
      exists = client.splits_to.where(split_into: candidate_id).exists?
      @logger.info "Checking split relationship: client=#{client.id} candidate=#{candidate_id} exists=#{exists}"
      exists
    end

    # Only use in development
    private def check_personal_ids(personal_id)
      return [] if personal_id.to_i.to_s == personal_id.to_s

      client_destinations.where(PersonalID: personal_id).pluck(:id)
    end

    private def build_destination_lookups
      @dest_name_lookup = GrdaWarehouse::ClientMatcherLookups::ProperNameLookup.new
      @dest_ssn_lookup = GrdaWarehouse::ClientMatcherLookups::SSNLookup.new
      @dest_dob_lookup = GrdaWarehouse::ClientMatcherLookups::DOBLookup.new
      @dest_clients_by_id = {}

      GrdaWarehouse::ClientMatcherLookups::ClientStub.from_scope(client_destinations) do |client|
        @dest_name_lookup.add(client)
        @dest_ssn_lookup.add(client)
        @dest_dob_lookup.add(client)
        @dest_clients_by_id[client.id] = client
      end
    end

    # Builds lookup tables for source clients to efficiently find matches based on name, SSN, and DOB
    # Creates three lookup tables:
    # - @source_name_lookup: Maps normalized names to client IDs
    # - @source_ssn_lookup: Maps SSNs to client IDs
    # - @source_dob_lookup: Maps dates of birth to client IDs
    # Stores all source clients in @source_clients array
    # Using the destination client's ID, but the source client's PII
    private def build_source_lookups
      @source_name_lookup = GrdaWarehouse::ClientMatcherLookups::ProperNameLookup.new
      @source_ssn_lookup = GrdaWarehouse::ClientMatcherLookups::SSNLookup.new
      @source_dob_lookup = GrdaWarehouse::ClientMatcherLookups::DOBLookup.new
      @source_clients = []

      clients = GrdaWarehouse::Hud::Client.joins(:warehouse_client_source).source
      # Use the Destination Client's ID, but the source client's PII
      id_field = Arel.sql(wc_t[:destination_id].to_sql)
      GrdaWarehouse::ClientMatcherLookups::ClientStub.from_scope(clients, id_field: id_field) do |client|
        @source_name_lookup.add(client)
        @source_ssn_lookup.add(client)
        @source_dob_lookup.add(client)
        @source_clients.push(client)
      end
    end

    # reshape for upsert, exclude names
    private def get_destination_client_by_id(id)
      found = @dest_clients_by_id[id]
      { SSN: found.ssn, DOB: found.dob, id: found.id }
    end
  end
end
