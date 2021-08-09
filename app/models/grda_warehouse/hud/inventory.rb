###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
    include ::HMIS::Structure::Inventory
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
    belongs_to :project_coc, class_name: 'GrdaWarehouse::Hud::ProjectCoc', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :inventories
    belongs_to :data_source

    alias_attribute :start_date, :InventoryStartDate
    alias_attribute :end_date, :InventoryEndDate
    alias_attribute :beds, :BedInventory

    scope :importable, -> do
      where(manual_entry: false)
    end

    scope :within_range, ->(range) do
      i_start = cl(i_t[:inventory_start_date_override], i_t[:InventoryStartDate])
      i_end = i_t[:InventoryEndDate]
      where(
        i_end.gteq(range.first).
        or(i_end.eq(nil)).
        and(i_start.lteq(range.last).
        or(i_start.eq(nil))),
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

    # when we export, we always need to replace InventoryID with the value of id
    # and ProjectID with the id of the related project
    def self.to_csv(scope:)
      attributes = hud_csv_headers.dup
      headers = attributes.clone
      attributes[attributes.index(:InventoryID)] = :id
      attributes[attributes.index(:ProjectID)] = 'project.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            attr = attr.to_s
            # we need to grab the appropriate id from the related project
            v = if attr.include?('.')
              obj, meth = attr.split('.')
              i.send(obj).send(meth)
            # These items are numeric and should not be null, assume 0 if empty
            elsif ['HMISParticipatingBeds', 'BedInventory', 'UnitInventory'].include? attr
              i.send(attr).presence || 0
            elsif attr == 'CoCCode' && i.coc_code_override.present?
              i.coc_code_override
            elsif attr == 'InventoryStartDate' && i.inventory_start_date_override.present?
              i.inventory_start_date_override
            elsif attr == 'InventoryEndDate' && i.inventory_end_date_override.present?
              i.inventory_end_date_override
            else
              i.send(attr)
            end
            if v.is_a? Date
              v = v.strftime('%Y-%m-%d')
            elsif v.is_a? Time
              v = v.to_formatted_s(:db)
            end
            v
          end
        end
      end
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
      end_date = [range.end, self.InventoryEndDate].compact.min
      days = (end_date - start_date).to_i

      (days.to_f * count / range.length).to_i rescue 0 # rubocop:disable Style/RescueModifier
    end
  end
end
