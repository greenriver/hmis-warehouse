###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class CurrentWaitlistsExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    # Generates the content of the Current Waitlists export
    def run!
      Rails.logger.info 'Generating content of Current Waitlists export'

      write_row(columns)
      total = candidates.count

      Rails.logger.info "There are #{total} candidates to export"

      groups_by_pool_id = unit_groups_by_pool_id

      candidates.find_each.with_index do |candidate, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        destination_client_id = candidate.client_proxy&.client_id
        next unless destination_client_id.present?

        # Format up to three priority scores for readability
        p1, p2, p3 = Array(candidate.priority_scores).first(3)

        Array.wrap(groups_by_pool_id[candidate.candidate_pool_id]).each do |unit_group|
          project = unit_group.project
          values = [
            destination_client_id,                  # PersonalID
            project.id,                             # ProjectID
            project.project_name,                   # ProjectName
            unit_group.name,                        # UnitGroupName
            candidate.created_at,                   # CreatedAt
            candidate.updated_at,                   # UpdatedAt
            p1,                                     # PriorityScore1
            p2,                                     # PriorityScore2
            p3,                                     # PriorityScore3
          ]
          write_row(values)
        end
      end
    end

    private

    def columns
      [
        'PersonalID',
        'ProjectID',
        'ProjectName',
        'UnitGroupName',
        'CreatedAt',
        'UpdatedAt',
        'PriorityScore1',
        'PriorityScore2',
        'PriorityScore3',
      ]
    end

    def candidates
      Hmis::Ce::Match::Candidate.
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
