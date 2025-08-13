###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern for handling client loading in cells controllers when artifacts are stored in S3
module HudReports
  module ArtifactAwareCells
    extend ActiveSupport::Concern

    private

    # Load clients for a specific cell, handling both RDS and S3 data sources
    def load_cell_clients(client_class, cell, table)
      if @report.artifacts_stored?
        load_clients_from_file(client_class, cell, table)
      else
        load_clients_from_db(client_class, cell, table)
      end
    end

    # Load clients using legacy database joins.
    # This will only return clients for reports whose data HAS NOT been stored in S3.
    # When a report is stored in S3, the data in these tables are cleared out.
    def load_clients_from_db(client_class, cell, table)
      client_class.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
    end

    # Load clients using S3 data.
    # This will only return clients for reports whose data HAS been stored in S3.
    def load_clients_from_file(client_class, cell, table)
      return client_class.none unless cell

      # This should work if we get the cell nam (i.e. "B3") or if we get the ReportCell object
      report_cell = if cell.is_a?(String)
        @report.report_cells.find_by(cell_name: cell, question: table)
      else
        cell.question == table ? cell : @report.report_cells.find_by(cell_name: cell.cell_name, question: table)
      end

      return client_class.none unless report_cell

      # Pull the csv file for the universe members from the universe_members_csv file for this question
      # Note: These files are sharded by report question/table
      service = HudReports::FileArtifactService.new(@report)
      universe_csv = service.retrieve_universe_members(question: table)
      return client_class.none unless universe_csv

      # Filter to the specific cell
      cell_members = universe_csv.select { |row| row['report_cell_id'].to_i == report_cell.id }
      member_ids = cell_members.map { |row| row['universe_membership_id'].to_i }.compact.uniq

      # Load the actual report client records from the report_clients_csv file
      # This file contains the client_id, source_enrollment_id, data_source_id, project_id, organization_id, and user_id
      # for each client in the report.
      clients_csv = service.retrieve_report_clients
      return client_class.none unless clients_csv

      # Filter the client data for the specific universe members and create temporary objects to build out the cell data
      matching_clients = clients_csv.select { |row| member_ids.include?(row['id'].to_i) }
      return create_temporary_cell_objects(matching_clients)
    end

    def create_temporary_cell_objects(csv_rows)
      # Create temporary objects from CSV data and attach preloaded warehouse clients and associations
      temporary_objects = []

      # Build out data that will be used in the cell data. These items are being preloaded and are being
      # used in calculations within a HUD report when displaying the cell data (e.g. PII calculations or
      # pulling names from these objects for a more user friendly display)
      client_ids = Set.new
      source_enrollment_ids = Set.new
      data_source_ids = Set.new
      project_ids = Set.new
      organization_ids = Set.new
      user_ids = Set.new

      csv_rows.each do |r|
        client_ids << r['client_id']&.to_i
        source_enrollment_ids << r['source_enrollment_id']&.to_i
        data_source_ids << r['data_source_id']&.to_i
        project_ids << r['project_id']&.to_i
        organization_ids << r['organization_id']&.to_i
        user_ids << r['user_id']&.to_i
      end

      actual_clients = GrdaWarehouse::Hud::Client.where(id: client_ids).
        preload(:data_source, :source_clients).
        index_by(&:id)

      enrollments_by_id = {}
      enrollments_by_id = GrdaWarehouse::Hud::Enrollment.where(id: source_enrollment_ids).preload(:client).index_by(&:id) if source_enrollment_ids.any?

      data_sources_by_id = {}
      data_sources_by_id = GrdaWarehouse::DataSource.where(id: data_source_ids).index_by(&:id) if data_source_ids.any?

      projects_by_id = {}
      projects_by_id = GrdaWarehouse::Hud::Project.where(id: project_ids).preload(:organization).index_by(&:id) if project_ids.any?

      organizations_by_id = {}
      organizations_by_id = GrdaWarehouse::Hud::Organization.where(id: organization_ids).index_by(&:id) if organization_ids.any?

      users_by_id = {}
      users_by_id = GrdaWarehouse::Hud::User.where(id: user_ids).index_by(&:id) if user_ids.any?

      csv_rows.each do |row|
        temporary_objects << HudReports::TemporaryCellRow.new(
          csv_row: row,
          client: actual_clients[row['client_id']&.to_i],
          source_enrollment: enrollments_by_id[row['source_enrollment_id']&.to_i],
          data_source: data_sources_by_id[row['data_source_id']&.to_i],
          project: projects_by_id[row['project_id']&.to_i],
          organization: organizations_by_id[row['organization_id']&.to_i],
          user: users_by_id[row['user_id']&.to_i],
        )
      end

      TemporaryCellCollection.new(temporary_objects)
    end
  end
end
