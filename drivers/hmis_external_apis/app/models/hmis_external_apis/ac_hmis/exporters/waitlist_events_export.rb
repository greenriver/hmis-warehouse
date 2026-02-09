###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class WaitlistEventsExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    # Generates the content of the Waitlist Events export
    def run!
      Rails.logger.info 'Generating content of Waitlist Events export'

      write_row(columns)
      total = events.count

      Rails.logger.info "There are #{total} waitlist events to export"

      # Precompute mapping from candidate_pool_id to associated unit groups (scoped to data_source)
      # This could be simplified in the future now that events are primarily keyed by Unit Group ID,
      # but we are leaving this unchanged for now since we are not backfilling existing events.
      groups_by_pool_id = unit_groups_by_pool_id

      events.find_each.with_index do |event, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        # Destination client id (warehouse client id) from the client proxy's client
        destination_client_id = event.client_proxy&.client_id
        next unless destination_client_id.present?

        # One row per unit group that references this candidate pool
        Array.wrap(groups_by_pool_id[event.candidate_pool_id]).each do |unit_group|
          project = unit_group.project
          values = [
            "#{event.id}_#{unit_group.id}", # ID
            destination_client_id,    # PersonalID (destination client id)
            project.id,               # ProjectID
            project.project_name,     # ProjectName
            unit_group.id,            # UnitGroupID
            unit_group.name,          # UnitGroupName
            event.event_name,         # EventName
            event.created_at,         # CreatedAt
          ]
          write_row(values)
        end
      end
    end

    private

    def columns
      [
        'ID',           # Stable ID for this row (concatenation of Hmis::Ce::Match::CandidateEvent#id and Hmis::UnitGroup#id)
        'PersonalID',   # Destination ID of client (warehouse client id)
        'ProjectID',    # ID of the project that uses the candidate pool
        'ProjectName',  # Name of the project that uses the candidate pool
        'UnitGroupID',  # ID of the unit group that uses the candidate pool
        'UnitGroupName', # Name of the unit group that uses the candidate pool
        'EventName',    # Event name (e.g., add, update, remove)
        'CreatedAt',    # Timestamp when the event was created
      ]
    end

    def events
      # Limit to events for candidate pools used by projects in this data source
      Hmis::Ce::Match::CandidateEvent.
        joins(:client_proxy).merge(Hmis::Ce::ClientProxy.for_warehouse_clients).
        where(candidate_pool_id: candidate_pool_ids_for_data_source).
        preload(:client_proxy)
    end

    def unit_groups_by_pool_id
      Hmis::UnitGroup.
        joins(:project).
        where(candidate_pool_id: candidate_pool_ids_for_data_source).
        where(Hmis::Hud::Project.arel_table[:data_source_id].eq(data_source.id)).
        preload(:project).
        group_by(&:candidate_pool_id)
    end

    def candidate_pool_ids_for_data_source
      @candidate_pool_ids_for_data_source ||= Hmis::Ce::Match::CandidatePool.
        joins(unit_groups: :project).
        where(Hmis::Hud::Project.arel_table[:data_source_id].eq(data_source.id)).
        distinct.
        pluck(:id)
    end
  end
end
