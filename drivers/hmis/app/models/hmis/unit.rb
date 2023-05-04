###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Unit < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_units

  # Type of this unit
  belongs_to :unit_type, class_name: 'Hmis::UnitType', optional: true
  # Periods when this unit has been active
  has_many :active_ranges, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  # User that last updated this unit
  belongs_to :user, class_name: 'User'

  # All historical and current occupancies of this unit
  has_many :unit_occupancies, class_name: 'Hmis::UnitOccupancy', inverse_of: :unit

  scope :of_type, ->(unit_type) { where(unit_type: unit_type) }

  def occupants_on(date = Date.today)
    enrollment_ids = Hmis::UnitOccupancy.active_on(date).where(unit: self).pluck(:enrollment_id)
    Hmis::Hud::Enrollment.where(id: enrollment_ids)
  end
  alias occupants occupants_on

  def start_date
    Hmis::ActiveRange.for_entity(self)&.start_date || inventory&.inventory_start_date
  end

  def end_date
    Hmis::ActiveRange.for_entity(self)&.end_date || inventory&.inventory_end_date
  end
end
