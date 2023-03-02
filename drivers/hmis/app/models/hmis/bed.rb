###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Bed < Hmis::HmisBase
  include Hmis::Hud::Concerns::HasEnums
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_beds
  belongs_to :unit, class_name: 'Hmis::Unit'
  has_one :inventory, through: :unit
  has_many :active_ranges, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  belongs_to :user, class_name: 'User'

  scope :active, ->(date = Date.today) do
    active_bed = ar_t[:end].eq(nil).or(ar_t[:end].gteq(date))
    active_inventory = i_t[:inventory_end_date].eq(nil).or(i_t[:inventory_end_date].gteq(date))

    joins(:inventory).left_outer_joins(:active_ranges).where(active_bed.and(active_inventory))
  end

  scope :inactive, ->(date = Date.today) do
    inactive_bed = ar_t[:end].not_eq(nil).and(ar_t[:end].lt(date))
    inactive_inventory = i_t[:inventory_end_date].not_eq(nil).and(i_t[:inventory_end_date].lt(date))

    joins(:inventory).left_outer_joins(:active_ranges).where(inactive_bed.or(inactive_inventory))
  end

  def start_date
    Hmis::ActiveRange.for_entity(self)&.start || unit.start_date
  end

  def end_date
    Hmis::ActiveRange.for_entity(self)&.end || unit.end_date
  end

  def self.bed_types
    {
      'ch_vet_bed_inventory' => 'Chronic Veteran',
      'youth_vet_bed_inventory' => 'Youth Veteran',
      'vet_bed_inventory' => 'Veteran',
      'ch_youth_bed_inventory' => 'Chronic Youth',
      'youth_bed_inventory' => 'Youth',
      'ch_bed_inventory' => 'Chronic',
      'other_bed_inventory' => 'Other',
    }
  end

  use_enum :bed_types_enum_map, bed_types
end
