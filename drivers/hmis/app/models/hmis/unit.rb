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
  # has_one :most_recent_pathways_or_rrh_assessment, -> do
  #   one_for_column(
  #     :AssessmentDate,
  #     source_arel_table: as_t,
  #     group_on: [:PersonalID, :data_source_id],
  #     scope: pathways_or_rrh,
  #   )
  # end, **hud_assoc(:PersonalID, 'Assessment')

  # scope :active, ->(date = Date.today) do
  #   active_unit = ar_t[:end].eq(nil).or(ar_t[:end].gteq(date))
  #   active_inventory = i_t[:inventory_end_date].eq(nil).or(i_t[:inventory_end_date].gteq(date))

  #   joins(:inventory).left_outer_joins(:active_ranges).where(active_unit.and(active_inventory))
  # end

  # scope :inactive, ->(date = Date.today) do
  #   inactive_unit = ar_t[:end].not_eq(nil).and(ar_t[:end].lt(date))
  #   inactive_inventory = i_t[:inventory_end_date].not_eq(nil).and(i_t[:inventory_end_date].lt(date))

  #   joins(:inventory).left_outer_joins(:active_ranges).where(inactive_unit.or(inactive_inventory))
  # end

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
