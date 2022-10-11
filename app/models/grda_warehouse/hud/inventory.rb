###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# From the Data Standards
# When a project reduces inventory, but will continue to serve the same household type with a smaller number of beds, a new record should be added with an 'Information Date’ of the effective date of the decrease; the same Inventory Start Date from the previous record should be used. The earlier record should be closed out by recording an Inventory End Date that is the day prior to the effective date of the decrease.
#
# This is the clearest indication of how the three dates are supposed to function.
# 1. InventoryStartDate is when the physical beds/units were constructed
# 2. InformationDate is the start of when the beds can be used/counted
# 3. InventoryEndDate when the beds are no longer available for use
module GrdaWarehouse::Hud
  class Inventory < Base
    include HudSharedScopes
    include ::HmisStructure::Inventory
    include ::HmisStructure::Shared
    include ArelHelper
    include RailsDrivers::Extensions
    require 'csv'

    attr_accessor :source_id

    self.table_name = 'Inventory'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    HOUSEHOLD_TYPES = {
      family: 3,
      individual: 1,
      child_only: 4,
    }.freeze

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :inventories, optional: true
    # has_one :project, through: :project_coc, source: :project
    has_one :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :inventories
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :inventories, optional: true
    belongs_to :project_coc, class_name: 'GrdaWarehouse::Hud::ProjectCoc', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :inventories, optional: true
    belongs_to :data_source

    alias_attribute :start_date, :InventoryStartDate
    alias_attribute :end_date, :InventoryEndDate
    alias_attribute :beds, :BedInventory

    scope :importable, -> do
      where(manual_entry: false)
    end

    scope :within_range, ->(range) do
      start_date = cl(i_t[:inventory_start_date_override], i_t[:InventoryStartDate])
      end_date = cl(i_t[:inventory_end_date_override], i_t[:InventoryEndDate])
      where(
        end_date.gteq(range.first).or(end_date.eq(nil)).
        and(start_date.lteq(range.last).or(start_date.eq(nil))),
      )
    end

    scope :active_on, ->(date) do
      date = date.to_date
      within_range(date..date)
    end

    scope :in_coc, ->(coc_code:) do
      coc_code = Array(coc_code)
      where(
        i_t[:CoCCode].in(coc_code).and(i_t[:coc_code_override].eq(nil).or(i_t[:coc_code_override].eq(''))).
        or(i_t[:coc_code_override].in(coc_code)),
      )
    end

    scope :serves_families, -> do
      where(HouseholdType: HOUSEHOLD_TYPES[:family])
    end

    scope :family, -> do
      serves_families
    end

    scope :serves_individuals, -> do
      where(i_t[:HouseholdType].not_eq(HOUSEHOLD_TYPES[:family]).
          or(i_t[:HouseholdType].eq(nil)))
    end

    scope :individual, -> do
      serves_individuals
    end

    scope :serves_children, -> do
      where(HouseholdType: HOUSEHOLD_TYPES[:child_only])
    end

    scope :overridden, -> do
      scope = where(Arel.sql('1=0'))
      override_columns.each_key do |col|
        scope = scope.or(where.not(col => nil))
      end
      scope
    end

    # If any of these are not blank, we'll consider it overridden
    def self.override_columns
      {
        coc_code_override: :CoCCode,
        inventory_start_date_override: :InventoryStartDate,
        inventory_end_date_override: :InventoryEndDate,
      }
    end

    def for_export
      fake_export = OpenStruct.new(include_deleted: false, period_type: 3)
      row = HmisCsvTwentyTwentyTwo::Exporter::Inventory::Overrides.apply_overrides(self, export: fake_export)
      row = HmisCsvTwentyTwentyTwo::Exporter::Inventory.adjust_keys(row)
      row
    end

    def self.related_item_keys
      [:ProjectID]
    end

    def self.household_types
      HOUSEHOLD_TYPES
    end

    def computed_start_date
      inventory_start_date_override.presence || self.InventoryStartDate
    end

    def computed_end_date
      inventory_end_date_override.presence || self.InventoryEndDate
    end

    # field is usually :UnitInventory or :BedInventory
    # range must be of type Filters::DateRange
    def average_daily_inventory(range:, field:)
      count = self[field]
      return 0 if count.blank? || count < 1

      start_date = [range.start, computed_start_date].compact.max
      end_date = [range.end, computed_end_date].compact.min
      days = (end_date - start_date).to_i
      return 0 if days.negative? || days.zero? || range.length.zero?

      (days.to_f * count / range.length).to_i
    end
  end
end
