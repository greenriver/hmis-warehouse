###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudHic
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :hic_projects_csv
        has_one_attached :hic_project_cocs_csv
        has_one_attached :hic_inventories_csv
        has_one_attached :hic_organizations_csv
        has_one_attached :hic_funders_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def shared_archival_entries(report_instance)
        {
          universe_members_csv: {
            scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
            filename: -> { "hud-hic-#{report_instance.id}-universe-members.csv" },
            delete_order: 1,
          },
          report_cells_csv: {
            scope: -> { report_instance.report_cells },
            filename: -> { "hud-hic-#{report_instance.id}-cells.csv" },
            delete_order: 99,
          },
        }
      end

      def archival_csv_config(report_instance)
        shared_archival_entries(report_instance).merge(
          hic_funders_csv: {
            scope: -> { HudHic::Fy2022::Funder.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-hic-#{report_instance.id}-funders.csv" },
            delete_order: 2,
          },
          hic_inventories_csv: {
            scope: -> { HudHic::Fy2022::Inventory.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-hic-#{report_instance.id}-inventories.csv" },
            delete_order: 3,
          },
          hic_project_cocs_csv: {
            scope: -> { HudHic::Fy2022::ProjectCoc.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-hic-#{report_instance.id}-project-cocs.csv" },
            delete_order: 4,
          },
          hic_organizations_csv: {
            scope: -> { HudHic::Fy2022::Organization.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-hic-#{report_instance.id}-organizations.csv" },
            delete_order: 5,
          },
          hic_projects_csv: {
            scope: -> { HudHic::Fy2022::Project.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-hic-#{report_instance.id}-projects.csv" },
            delete_order: 6,
          },
        )
      end
    end
  end
end
