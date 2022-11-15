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

  scope :viewable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
  end

  scope :editable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.editable_by(user))
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
      :InventoryStartDate,
    ]
  end

  def active
    return true unless inventory_end_date.present?

    inventory_end_date >= Date.today
  end
end
