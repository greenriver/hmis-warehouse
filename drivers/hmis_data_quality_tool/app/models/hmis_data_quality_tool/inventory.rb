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
        project_name: { title: 'Project Name' },
        inventory_id: { title: 'Inventory ID' },
        hmis_inventory_id: { title: 'HMIS Inventory ID' },
        project_type: { title: 'Project Type' },
        project_operating_start_date: { title: 'Project Operating Start Date' },
        project_operating_end_date: { title: 'Project Operating End Date' },
        inventory_start_date: { title: 'Inventory Start Date' },
        inventory_end_date: { title: 'Inventory End Date' },
        unit_inventory: { title: 'Unit Inventory' },
        bed_inventory: { title: 'Bed Inventory' },
        ch_vet_bed_inventory: { title: 'Chronic Veteran Bed Inventory' },
        youth_vet_bed_inventory: { title: 'Youth Veteran Bed Inventory' },
        vet_bed_inventory: { title: 'Veteran Bed Inventory' },
        ch_youth_bed_inventory: { title: 'Chronic Youth Bed Inventory' },
        youth_bed_inventory: { title: 'Youth Bed Inventory' },
        ch_bed_inventory: { title: 'Chronic Bed Inventory' },
        other_bed_inventory: { title: 'Other Bed Inventory' },
      }.freeze
    end

    def self.detail_headers_for_export
      detail_headers
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
          sections(report).each do |_, calc|
            section_title = calc[:title]
            intermediate[section_title] ||= { denominator: {}, invalid: {} }
            intermediate[section_title][:denominator][inventory] = item if calc[:denominator].call(item)
            intermediate[section_title][:invalid][inventory] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, item_batch|
          import_intermediate!(item_batch[:denominator].values)
          report.universe("#{section_title}__denominator").add_universe_members(item_batch[:denominator]) if item_batch[:denominator].present?
          report.universe("#{section_title}__invalid").add_universe_members(item_batch[:invalid]) if item_batch[:invalid].present?

          report_items.merge!(item_batch)
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
      report_item.project_operating_start_date = project.operating_start_date_to_use
      report_item.project_operating_end_date = project.operating_end_date_to_use
      report_item.inventory_start_date = inventory.computed_start_date
      report_item.inventory_end_date = inventory.computed_end_date
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

    def self.sections(_)
      {
        dedicated_bed_issues: {
          title: 'Sum of Dedicated Beds does not Equal Total Beds',
          description: 'Dedicated beds count must be equal to the total beds available',
          required_for: 'All',
          denominator: ->(_item) {
            true
          },
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
