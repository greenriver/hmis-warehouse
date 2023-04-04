###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Inventory < Hmis::Hud::Base
  self.table_name = :Inventory
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Inventory
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  validates_with Hmis::Hud::Validators::InventoryValidator

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_many :units, dependent: :destroy
  has_many :beds, through: :units
  belongs_to :user, **hmis_relation(:UserID, 'User')

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
