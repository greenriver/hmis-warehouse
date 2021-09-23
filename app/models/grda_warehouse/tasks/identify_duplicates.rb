###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
      if GrdaWarehouseBase.advisory_lock_exists?('identify_duplicates')
        msg = 'Skipping identify duplicates, all ready running.'
        logger.warn msg
        @notifier.ping(msg) if @send_notifications
        return
      end
      GrdaWarehouseBase.with_advisory_lock('identify_duplicates') do
        restore_previously_deleted_destinations
        Rails.logger.info 'Loading unprocessed clients'
        started_at = DateTime.now
        @unprocessed = load_unprocessed

        @dnd_warehouse_data_source = GrdaWarehouse::DataSource.destination.first
        return unless @dnd_warehouse_data_source

        # compare unprocessed to destinations, looking for a match
        # If we don't find a match:
        #   create a new destination (based on the unprocessed client)
        #   add a associated record to WarehouseClient
        # If we do find a match:
        #   create the associated WarehouseClient

        Rails.logger.info "Matching #{@unprocessed.size} unprocessed clients"
        matched = 0
        new_created = 0
        @unprocessed.each_with_index do |c, index|
          match = check_for_obvious_match(c)
          client = GrdaWarehouse::Hud::Client.find(c)
          if match.present?
            matched += 1
            destination_client = GrdaWarehouse::Hud::Client.find(match)
            destination_client.invalidate_service_history
            # Set SSN & DOB if we have it in the incoming client, but not in the destination
            should_save = false
            if client.DOB.present? && destination_client.DOB.blank?
              destination_client.DOB = client.DOB
              should_save = true
            end
            if client.SSN.present? && destination_client.SSN.blank?
              destination_client.SSN = client.SSN
              should_save = true
            end

            destination_client.save if should_save
          else
            new_created += 1
            destination_client = client.dup
            destination_client.data_source_id = @dnd_warehouse_data_source.id
            destination_client.save
          end
          GrdaWarehouse::WarehouseClient.create(
            id_in_source: client.PersonalID,
            source_id: client.id,
            destination_id: destination_client.id,
            data_source_id: client.data_source_id,
          )

          print "Matched: #{index} #{DateTime.now}\n" if (index % 1000).zero? && index.positive?
        end
        completed_at = DateTime.now
        GrdaWarehouse::IdentifyDuplicatesLog.create(
          started_at: started_at,
          completed_at: completed_at,
          to_match: @unprocessed.size,
          matched: matched,
          new_created: new_created,
        )
        Rails.logger.info 'Done'
      end
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
          @notifier.ping("Unable to merge #{source.id} with #{destination.id}") if @send_notifications
          Rails.logger.error(e.to_s)
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
        matches_name = []
        matches_dob = []
        matches_ssn = []

        splits = splits_by_from[dest_id]&.flatten || [] # Don't re-merge anybody that was split off from this candidate
        splits += splits_by_into[dest_id]&.flatten || [] # Don't merge with anybody that this candidate was split off from

        if first_name && last_name
          key = [first_name.downcase.strip.gsub(/[^a-z0-9]/i, ''), last_name.downcase.strip.gsub(/[^a-z0-9]/i, '')]
          matches_name += source_clients_grouped_by_name[key].map(&:last).uniq - [dest_id]
        end

        matches_ssn += source_clients_grouped_by_ssn[ssn].map(&:last).uniq - [dest_id] if valid_social?(ssn)
        matches_dob += source_clients_grouped_by_dob[dob].map(&:last).uniq - [dest_id] if dob
        all_matching_dest_ids = (matches_name + matches_ssn + matches_dob) - splits
        to_merge_by_dest_id = all_matching_dest_ids.uniq.
          map { |num| [num, all_matching_dest_ids.count(num)] }.to_h.
          select { |_, v| v > 1 }

        to_merge += to_merge_by_dest_id.keys.map { |source_id| [dest_id, source_id].sort } if to_merge_by_dest_id.any?
      end
      return to_merge
    end

    def source_clients_grouped_by_name
      @source_clients_grouped_by_name ||= all_source_clients.group_by { |first_name, last_name, _, _, _| [first_name.downcase, last_name.downcase] }
    end

    def source_clients_grouped_by_ssn
      @source_clients_grouped_by_ssn ||= all_source_clients.group_by { |_, _, ssn, _, _| ssn }
    end

    def source_clients_grouped_by_dob
      @source_clients_grouped_by_dob ||= all_source_clients.group_by { |_, _, _, dob, _| dob }
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
      source_client_ids = GrdaWarehouse::Hud::Client.source.select(:id)
      deleted_destination_ids = GrdaWarehouse::WarehouseClient.
        where(source_id: source_client_ids).
        where.not(destination_id: client_destinations.select(:id)).select(:destination_id)
      return unless deleted_destination_ids.present?

      @notifier.ping("Restoring #{deleted_destination_ids.count} destination clients and invalidating their data")
      client_destinations.only_deleted.where(id: deleted_destination_ids).find_each(&:force_full_service_history_rebuild)
      client_destinations.only_deleted.where(id: deleted_destination_ids).update_all(DateDeleted: nil)
    end

    # figure out who doesn't yet have an entry in warehouse clients
    private def load_unprocessed
      GrdaWarehouse::Hud::Client.source.pluck(:id) - GrdaWarehouse::WarehouseClient.pluck(:source_id)
    end

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    private def client_destinations
      GrdaWarehouse::Hud::Client.destination
    end

    # Look for really clear matches (2 of the following 3 should be good):
    #   1. valid social and last 4 of social or entire social match
    #   2. birthdate matches
    #   3. perfect name matches
    private def check_for_obvious_match client_id
      client = GrdaWarehouse::Hud::Client.find(client_id.to_i)

      ssn_matches = []
      ssn_matches = check_social client.SSN if valid_social?(client.SSN)

      birthdate_matches = []
      birthdate_matches = check_birthday client.DOB if client.DOB.present?

      name_matches = []
      name_matches = check_name client if client.FirstName.present? && client.last_name.present?

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
      ::HUD.valid_social? ssn
    end

    private def check_social ssn
      client_destinations.where(SSN: ssn).pluck(:id)
    end

    private def check_birthday dob
      client_destinations.where(DOB: dob).where.not(DOB: nil).pluck(:id)
    end

    private def check_name client
      client_destinations.
        where(
          FirstName: client.FirstName,
          LastName: client.LastName,
        ).
        pluck(:id)
    end
  end
end
