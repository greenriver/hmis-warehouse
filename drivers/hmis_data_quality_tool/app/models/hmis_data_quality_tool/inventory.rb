###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Inventory < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_inventories'
    include ArelHelper
    include DqConcern
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :inventory, class_name: 'GrdaWarehouse::Hud::Inventory', optional: true

    def self.detail_headers
      {
        project_name: 'Project Name',
        inventory_id: 'Inventory ID',
        hmis_inventory_id: 'HMIS Inventory ID',
        project_type: 'Project Type',
        project_operating_start_date: 'Project Operating Start Date',
        project_operating_end_date: 'Project Operating End Date',
        inventory_start_date: 'Inventory Start Date',
        inventory_end_date: 'Inventory End Date',
        unit_inventory: 'Unit Inventory',
        bed_inventory: 'Bed Inventory',
        ch_vet_bed_inventory: 'Chronic Veteran Bed Inventory',
        youth_vet_bed_inventory: 'Youth Veteran Bed Inventory',
        vet_bed_inventory: 'Veteran Bed Inventory',
        ch_youth_bed_inventory: 'Chronic Youth Bed Inventory',
        youth_bed_inventory: 'Youth Bed Inventory',
        ch_bed_inventory: 'Chronic Bed Inventory',
        other_bed_inventory: 'Other Bed Inventory',
      }.freeze
    end

    def self.calculate(report_items:, report:)
      inventory_scope(report).find_in_batches do |batch|
        intermediate = {}
        batch.each do |inventory|
          item = report_item_fields_from_inventory(
            report_items: report_items,
            inventory: inventory,
            report: report,
          )
          sections.each do |_, calc|
            section_title = calc[:title]
            intermediate[section_title] ||= {}
            intermediate[section_title][inventory] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, inventory_batch|
          import_intermediate!(inventory_batch.values)
          report.universe(section_title).add_universe_members(inventory_batch) if inventory_batch.present?

          report_items.merge!(inventory_batch)
        end
      end
      report_items
    end

    def self.inventory_scope(report)
      GrdaWarehouse::Hud::Inventory.joins(:project).
        preload(:project).
        within_range(report.filter.range).
        merge(GrdaWarehouse::Hud::Project.where(id: report.filter.anded_effective_project_ids)).distinct
    end

    def self.report_item_fields_from_inventory(report_items:, inventory:, report:)
      report_item = report_items[inventory]
      return report_item if report_item.present?

      project = inventory.project
      report_item = new(
        report_id: report.id,
        inventory_id: inventory.id,
      )
      report_item.project_id = project.id
      report_item.project_name = project.name(report.user)
      report_item.hmis_inventory_id = inventory.InventoryID
      report_item.data_source_id = inventory.data_source_id
      report_item.project_type = project.project_type_to_use
      report_item.project_operating_start_date = project.OperatingStartDate
      report_item.project_operating_end_date = project.OperatingEndDate
      report_item.inventory_start_date = inventory.InventoryStartDate
      report_item.inventory_end_date = inventory.InventoryEndDate
      report_item.unit_inventory = inventory.UnitInventory
      report_item.bed_inventory = inventory.BedInventory
      report_item.ch_vet_bed_inventory = inventory.CHVetBedInventory
      report_item.youth_vet_bed_inventory = inventory.YouthVetBedInventory
      report_item.vet_bed_inventory = inventory.VetBedInventory
      report_item.ch_youth_bed_inventory = inventory.CHYouthBedInventory
      report_item.youth_bed_inventory = inventory.YouthBedInventory
      report_item.ch_bed_inventory = inventory.CHBedInventory
      report_item.other_bed_inventory = inventory.OtherBedInventory
      report_item
    end

    def self.sections
      {
        dedicated_bed_issues: {
          title: 'Sum of Dedicated Beds does not Equal Total Beds',
          description: 'Dedicated beds count must be equal to the total beds available',
          limiter: ->(item) {
            sum_dedicated_beds = [
              item.ch_vet_bed_inventory,
              item.youth_vet_bed_inventory,
              item.vet_bed_inventory,
              item.ch_youth_bed_inventory,
              item.youth_bed_inventory,
              item.ch_bed_inventory,
              item.other_bed_inventory,
            ].compact.sum
            item.bed_inventory != sum_dedicated_beds
          },
        },
      }.freeze
    end
  end
end
