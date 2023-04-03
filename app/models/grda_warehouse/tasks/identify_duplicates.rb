###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class IdentifyDuplicates
    include ArelHelper
    include NotifierConfig

    def initialize(run_post_processing: true)
      setup_notifier('IdentifyDuplicates')
      @run_post_processing = run_post_processing
      super()
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
            destination_client = destination_clients_by_id[match_id]

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

            destination_client_updates << destination_client if should_save
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
          destination_client_updates,
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

    # look at all existing records for duplicates and merge destination clients
    def match_existing!
      @to_merge = find_merge_candidates
      user = User.setup_system_user

      @to_merge.each do |destination_id, source_id|
        # If this pair was previously a candidate match, mark it as accepted
        GrdaWarehouse::ClientMatch.processed_or_candidate.where(
          source_client_id: source_id,
          destination_client_id: destination_id,
        ).find_each do |client_match|
          client_match.flag_as(status: 'accepted')
        end

        # Detect a previous merge
        destination_id = find_current_id_for(destination_id)
        next unless destination_id.present?

        # Detect a previous merge
        source_id = find_current_id_for(source_id)
        next unless source_id.present?
        # This has already been fully merged
        next if source_id == destination_id

        destination = client_destinations.find(destination_id)
        source = client_destinations.find(source_id)
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
      return unless @run_post_processing

      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
    end

    def find_current_id_for(id)
      return merge_history.current_destination(id) unless client_destinations.where(id: id).exists?

      return id
    end

    def merge_history
      @merge_history ||= GrdaWarehouse::ClientMergeHistory.new
    end

    def find_merge_candidates
      to_merge = Set.new
      all_splits = GrdaWarehouse::ClientSplitHistory.pluck(:split_from, :split_into)
      splits_by_from = all_splits.group_by(&:first)
      splits_by_into = all_splits.group_by(&:last)

      all_source_clients.each do |first_name, last_name, ssn, dob, dest_id|
        splits = splits_by_from[dest_id]&.flatten || [] # Don't re-merge anybody that was split off from this candidate
        splits += splits_by_into[dest_id]&.flatten || [] # Don't merge with anybody that this candidate was split off from

        matches_name = (check_name(first_name, last_name, source_clients_grouped_by_name) - [dest_id])
        matches_ssn = (check_social(ssn, source_clients_grouped_by_ssn) - [dest_id])
        matches_dob = (check_birthday(dob, source_clients_grouped_by_dob) - [dest_id])
        all_matching_dest_ids = (matches_name + matches_ssn + matches_dob) - splits
        # to_merge_by_dest_id = Set.new
        # seen = Set.new
        # all_matching_dest_ids.each do |num|
        #   if seen.include?(num)
        #     to_merge_by_dest_id << num
        #   else
        #     seen << num
        #   end
        # end
        to_merge_by_dest_id = all_matching_dest_ids.uniq.
          map { |num| [num, all_matching_dest_ids.count(num)] }.to_h.
          select { |_, v| v > 1 }

        to_merge += to_merge_by_dest_id.keys.map { |source_id| [dest_id, source_id].sort } if to_merge_by_dest_id.any?
      end
      return to_merge
    end

    def source_clients_grouped_by_name
      @source_clients_grouped_by_name ||= all_source_clients.group_by { |first_name, last_name, _, _, _| [first_name.downcase, last_name.downcase] }.
        transform_values { |values| values.map(&:last) }
    end

    def source_clients_grouped_by_ssn
      @source_clients_grouped_by_ssn ||= all_source_clients.group_by { |_, _, ssn, _, _| ssn }.
        transform_values { |values| values.map(&:last) }
    end

    def source_clients_grouped_by_dob
      @source_clients_grouped_by_dob ||= all_source_clients.group_by { |_, _, _, dob, _| dob }.
        transform_values { |values| values.map(&:last) }
    end

    def all_source_clients
      @all_source_clients ||= GrdaWarehouse::Hud::Client.joins(:warehouse_client_source).source.
        pluck(:FirstName, :LastName, :SSN, :DOB, Arel.sql(wc_t[:destination_id].to_sql)).
        map do |first_name, last_name, ssn, dob, id|
          clean_first_name = first_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
          clean_last_name = last_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
          [clean_first_name, clean_last_name, ssn, dob, id]
        end
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

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    private def client_destinations
      GrdaWarehouse::Hud::Client.destination
    end

    # Look for really clear matches (2 of the following 3 should be good):
    #   1. valid social and last 4 of social or entire social match
    #   2. birthdate matches
    #   3. perfect name matches
    private def check_for_obvious_match(client)
      ssn_matches = check_social(client.SSN, destination_clients_grouped_by_ssn)
      birthdate_matches = check_birthday(client.DOB, destination_clients_grouped_by_dob)
      name_matches = check_name(client.first_name, client.last_name, destination_clients_grouped_by_name)

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

    private def check_personal_ids(personal_id)
      return [] if personal_id.to_i.to_s == personal_id.to_s

      client_destinations.where(PersonalID: personal_id).pluck(:id)
    end

    private def valid_social? ssn
      ::HudUtility.valid_social? ssn
    end

    private def check_social(ssn, ssn_group)
      return [] unless valid_social?(ssn)

      ssn_group[ssn]&.uniq || []
    end

    private def check_birthday(dob, dob_group)
      return [] unless dob.present?

      dob_group[dob]&.uniq || []
    end

    private def check_name(first_name, last_name, name_group)
      clean_first_name = first_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
      clean_last_name = last_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
      return [] unless clean_first_name.present? && clean_last_name.present?

      name_group[[clean_first_name, clean_last_name]]&.uniq || []
    end

    private def all_destination_clients
      @all_destination_clients ||= GrdaWarehouse::Hud::Client.destination.
        pluck(:FirstName, :LastName, :SSN, :DOB, :id).
        map do |first_name, last_name, ssn, dob, id|
        clean_first_name = first_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
        clean_last_name = last_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
        [clean_first_name, clean_last_name, ssn, dob, id]
      end
    end

    private def destination_clients_grouped_by_name
      @destination_clients_grouped_by_name ||= all_destination_clients.group_by { |first_name, last_name, _, _, _| [first_name, last_name] }.
        transform_values { |values| values.map(&:last) }
    end

    private def destination_clients_grouped_by_ssn
      @destination_clients_grouped_by_ssn ||= all_destination_clients.group_by { |_, _, ssn, _, _| ssn }.
        transform_values { |values| values.map(&:last) }
    end

    private def destination_clients_grouped_by_dob
      @destination_clients_grouped_by_dob ||= all_destination_clients.group_by { |_, _, _, dob, _| dob }.
        transform_values { |values| values.map(&:last) }
    end

    private def destination_clients_by_id
      @destination_clients_by_id ||= all_destination_clients.group_by { |_, _, _, _, dest_id| dest_id }.
        transform_values { |values| values.map { |client| { SSN: client[2], DOB: client[3], id: client[4] } }.first }
    end
  end
end
