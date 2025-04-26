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

    def identify_duplicates
      build_source_lookups
      build_destination_lookups
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

      Rails.logger.info "Matching #{unprocessed.count} unprocessed clients"
      matched = 0
      new_created = 0
      unprocessed.find_in_batches do |batch|
        matched_ids = []
        destination_client_updates = []
        new_destination_clients = []
        new_warehouse_clients = {}
        source_client_ids_with_new_destination_clients = []
        batch.each do |client|
          match_id = check_for_obvious_match(client)
          if match_id.present?
            matched += 1
            matched_ids << match_id
            destination_client = get_destination_client_by_id(match_id)

            # Set SSN & DOB if we have it in the incoming client, but not in the destination
            should_save = false
            if client.DOB.present? && destination_client[:DOB].blank?
              destination_client[:DOB] = client.DOB
              should_save = true
            end
            if client.SSN.present? && destination_client[:SSN].blank?
              destination_client[:SSN] = client.SSN
              should_save = true
            end
            if should_save
              # set non-nullable fields, these aren't used because of the column limitation on import
              # but Postgres complains if they aren't there
              destination_client[:PersonalID] = client.PersonalID
              destination_client[:data_source_id] = @dnd_warehouse_data_source.id
              destination_client_updates << destination_client
            end
          else
            new_created += 1
            destination_client = client.dup
            destination_client.data_source_id = @dnd_warehouse_data_source.id
            destination_client.apply_housing_release_status
            new_destination_clients << destination_client
            source_client_ids_with_new_destination_clients << client.id
          end

          new_warehouse_clients[client.id] = GrdaWarehouse::WarehouseClient.new(
            id_in_source: client.PersonalID,
            source_id: client.id,
            destination_id: destination_client[:id], # Nil if no destination client exists
            data_source_id: client.data_source_id,
          )
        end
        GrdaWarehouse::Hud::Client.import(
          destination_client_updates.uniq { |m| m[:id] }, # ensure no duplicate rows
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:SSN, :DOB],
          },
          validate: false,
        )
        new_destination_ids = GrdaWarehouse::Hud::Client.import(new_destination_clients).ids
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
        to_match: unprocessed.count,
        matched: matched,
        new_created: new_created,
      )
      Rails.logger.info 'Done'
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

    # look at all existing records for duplicates and merge destination clients
    # We'll do as much of this in the database as possible for performance and memory management
    def match_existing!
      user = User.setup_system_user

      unmatchable_destination_ids_set = unmatchable_destination_ids.pluck(:destination_id).to_set
      find_merge_candidates.each_slice(500) do |batch|
        client_lookups = GrdaWarehouse::Hud::Client.where(id: batch.flatten).index_by(&:id)
        batch.each do |destination_id, source_id|
          destination = client_lookups[destination_id]
          source = client_lookups[source_id]
          next unless destination.present? && source.present?

          # If this pair was previously a candidate match, mark it as accepted
          mark_as_accepted(source_id, destination_id) if previous_candidate_matches.include?([source_id, destination_id])
          mark_as_accepted(destination_id, source_id) if previous_candidate_matches.include?([destination_id, source_id])

          # Confirm neither client has exceeded the MAX_SOURCE_CLIENTS limit
          if unmatchable_destination_ids_set.include?(destination_id) || unmatchable_destination_ids_set.include?(source_id)
            Rails.logger.warn "Skipping merge of #{source_id} and #{destination_id} because one has exceeded the MAX_SOURCE_CLIENTS limit"
            next
          end

          begin
            destination.merge_from(source, reviewed_by: user, reviewed_at: DateTime.current)
          rescue Exception => e
            Rails.logger.error(e.to_s)
            if @send_notifications
              @notifier.ping(
                "Unable to merge #{source.id} with #{destination.id}",
                {
                  exception: e,
                  info: {
                    source_id: source.id,
                    destination_id: destination.id,
                  },
                },
              )
            end
          end
          Rails.logger.info "merged #{source.id} into #{destination.id}"
        end
      end
      return unless @run_post_processing

      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
    end

    # def joins_warehouse_clients_enrollment_and_project
    #   <<-SQL
    #     inner join warehouse_clients on clients.id = warehouse_clients.source_id
    #     -- inner join "Enrollment" as en on clients."PersonalID" = en."PersonalID"
    #     --   and en.data_source_id = clients.data_source_id
    #     --   and en."DateDeleted" is NULL
    #     -- inner join "Project" as p on en."ProjectID" = p."ProjectID"
    #     --   and p.data_source_id = clients.data_source_id
    #     --   and p."DateDeleted" is NULL
    #   SQL
    # end

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

    private def find_current_id_for(id)
      return merge_history.current_destination(id) unless client_destinations.where(id: id).exists?

      return id
    end

    private def merge_history
      @merge_history ||= GrdaWarehouse::ClientMergeHistory.new
    end

    private def find_merge_candidates
      to_merge = Set.new
      # Never return obvious matches if auto deduplication is disabled
      return to_merge unless GrdaWarehouse::Config.get(:enable_auto_deduplication)

      # Find all potential matches
      # Potential matches are clients with at least two matching, Name, SSN, or DOB
      ssn_matches = exact_ssn_matches
      # [1100700, 2605522]
      name_matches = exact_name_matches
      dob_matches = exact_dob_matches

      matches = {}
      ssn_matches.each do |k|
        matches[k] ||= 0
        matches[k] += 1
      end
      name_matches.each do |k|
        matches[k] ||= 0
        matches[k] += 1
      end
      dob_matches.each do |k|
        matches[k] ||= 0
        matches[k] += 1
      end
      more_than_one_match = matches.select { |_, v| v > 1 }

      # NOTE: split_from is the previous destination client id, split_into the new destination client id
      all_splits = GrdaWarehouse::ClientSplitHistory.pluck(:split_from, :split_into)

      # Filter more_than_one_match removing any that were split previously
      # Note that more_than_one_match will always have sorted pairs for keys given
      # `WHERE client_one_dob_id < client_two_dob_id`
      all_splits.each do |row|
        more_than_one_match.delete(row.sort)
      end
      more_than_one_match.keys

      # # Source client PII with destination client ID
      # @source_clients.each do |target|
      #   splits = splits_by_from[target.id]&.flatten || [] # Don't re-merge anybody that was split off from this candidate
      #   splits += splits_by_into[target.id]&.flatten || [] # Don't merge with anybody that this candidate was split off from

      #   matches_name = @source_name_lookup.get_ids(first_name: target.first_name, last_name: target.last_name)
      #   matches_ssn = @source_ssn_lookup.get_ids(ssn: target.ssn)
      #   matches_dob = @source_dob_lookup.get_ids(dob: target.dob)
      #   all_matching_dest_ids = (matches_name + matches_ssn + matches_dob) - splits
      #   all_matching_dest_ids.filter! { |id| id != target.id }
      #   # to_merge_by_dest_id = Set.new
      #   # seen = Set.new
      #   # all_matching_dest_ids.each do |num|
      #   #   if seen.include?(num)
      #   #     to_merge_by_dest_id << num
      #   #   else
      #   #     seen << num
      #   #   end
      #   # end
      #   to_merge_by_dest_id = all_matching_dest_ids.uniq.
      #     map { |num| [num, all_matching_dest_ids.count(num)] }.to_h.
      #     select { |_, v| v > 1 }

      #   to_merge += to_merge_by_dest_id.keys.map { |source_id| [target.id, source_id].sort } if to_merge_by_dest_id.any?
      # end

      # return to_merge
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
      @unprocessed ||= GrdaWarehouse::Hud::Client.where(
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
      client.splits_to.where(split_into: candidate_id).exists?
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
