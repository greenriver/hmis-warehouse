###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Inventory < Hmis::Hud::Base
  include ::HmisStructure::Inventory
  include ::Hmis::Hud::Shared
  self.table_name = :Inventory
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  validates_with Hmis::Hud::Validators::InventoryValidator

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, **hmis_relation(:ProjectID, 'Project')

  use_enum :household_type_enum_map, ::HUD.household_types
  use_enum :availability_enum_map, ::HUD.availabilities
  use_enum :bed_type_enum_map, ::HUD.bed_types

  scope :viewable_by, ->(user) do
    viewable_projects = Hmis::Hud::Project.viewable_by(user).pluck(:project_id)
    where(project_id: viewable_projects)
  end

  SORT_OPTIONS = [:start_date].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :start_date
      order(inventory_start_date: :desc)
    else
      raise NotImplementedError
    end
  end

  def required_fields
    @required_fields ||= [
      :ProjectID,
      :CoCCode,
      :InventoryStartDate,
      :HouseholdType,
      :UnitInventory,
      :BedInventory,
    ]
  end
end
