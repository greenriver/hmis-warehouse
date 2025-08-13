###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern for handling client loading in cells controllers when artifacts are stored in S3
module HudReports
  module ArtifactAwareCells
    require_relative 'temporary_cell_row'
    require_relative 'temporary_cell_collection'
    extend ActiveSupport::Concern

    private

    # Load clients for a specific cell, handling both RDS and S3 data sources
    def load_cell_clients(client_class, cell, table)
      if @report.artifacts_stored?
        load_clients_from_s3(client_class, cell, table)
      else
        load_clients_from_rds(client_class, cell, table)
      end
    end

    # Load clients using legacy database joins.
    # This will only return clients for reports whose data HAS NOT been stored in S3.
    # When a report is stored in S3, the data in these tables are cleared out.
    def load_clients_from_rds(client_class, cell, table)
      client_class.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
    end

    # Load clients using S3 data.
    # This will only return clients for reports whose data HAS been stored in S3.
    def load_clients_from_s3(client_class, cell, table)
      return client_class.none unless cell

      # This should work if we get the cell nam (i.e. "B3") or if we get the ReportCell object
      report_cell = if cell.is_a?(String)
        @report.report_cells.find_by(cell_name: cell, question: table)
      else
        cell.question == table ? cell : @report.report_cells.find_by(cell_name: cell.cell_name, question: table)
      end

      return client_class.none unless report_cell

      # Pull the csv file for the universe members from the universe_members_csv file for this question
      # NOte: These files are sharded by report question/table
      service = HudReports::S3ArtifactService.new(@report)
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

      # Filter the client datafor the specific universe members and create temporary objects to build out the cell data
      matching_clients = clients_csv.select { |row| member_ids.include?(row['id'].to_i) }
      return create_temporary_cell_objects(matching_clients)
    end

    def create_temporary_cell_objects(csv_rows)
      # Create temporary objects from CSV data and attach preloaded warehouse clients and associations
      temporary_objects = []

      # Build out data that will be used in the cell data. These items are being preloaded as are being
      # used in calculations within a HUD report when displaying the cell data (e.g. PII calculations or
      # pulling names from these objects for a more user friendly display)
      client_ids = csv_rows.map { |r| r['client_id']&.to_i }.compact.uniq
      source_enrollment_ids = csv_rows.map { |r| r['source_enrollment_id']&.to_i }.compact.uniq
      data_source_ids = csv_rows.map { |r| r['data_source_id']&.to_i }.compact.uniq
      project_ids = csv_rows.map { |r| r['project_id']&.to_i }.compact.uniq
      organization_ids = csv_rows.map { |r| r['organization_id']&.to_i }.compact.uniq
      user_ids = csv_rows.map { |r| r['user_id']&.to_i }.compact.uniq

      actual_clients = GrdaWarehouse::Hud::Client.where(id: client_ids).
        preload(:data_source, :source_clients).
        index_by(&:id)

      enrollments_by_id = if source_enrollment_ids.any?
        GrdaWarehouse::Hud::Enrollment.where(id: source_enrollment_ids).preload(:client).index_by(&:id)
      else
        {}
      end

      data_sources_by_id = if data_source_ids.any?
        GrdaWarehouse::DataSource.where(id: data_source_ids).index_by(&:id)
      else
        {}
      end

      projects_by_id = if project_ids.any?
        GrdaWarehouse::Hud::Project.where(id: project_ids).preload(:organization).index_by(&:id)
      else
        {}
      end

      organizations_by_id = if organization_ids.any?
        GrdaWarehouse::Hud::Organization.where(id: organization_ids).index_by(&:id)
      else
        {}
      end

      users_by_id = if user_ids.any?
        GrdaWarehouse::Hud::User.where(id: user_ids).index_by(&:id)
      else
        {}
      end

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
