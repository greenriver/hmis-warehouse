###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Unit < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_units

  belongs_to :project, class_name: 'Hmis::Hud::Project'
  # Type of this unit
  belongs_to :unit_type, class_name: 'Hmis::UnitType', optional: true
  # Periods when this unit has been active
  has_many :active_ranges, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  # User that last updated this unit
  belongs_to :user, class_name: 'User'

  # All historical and current occupancies of this unit
  has_many :unit_occupancies, class_name: 'Hmis::UnitOccupancy', inverse_of: :unit

  alias_attribute :date_updated, :updated_at
  alias_attribute :date_created, :created_at

  scope :of_type, ->(unit_type) { where(unit_type: unit_type) }

  scope :occupied_on, ->(date = Date.current) do
    unit_ids = joins(:unit_occupancies).merge(Hmis::UnitOccupancy.active_on(date)).pluck(:id)
    where(id: unit_ids)
  end

  scope :unoccupied_on, ->(date = Date.current) do
    occupied_unit_ids = joins(:unit_occupancies).merge(Hmis::UnitOccupancy.active_on(date)).pluck(:id)
    where.not(id: occupied_unit_ids)
  end

  scope :active, ->(date = Date.current) do
    active_unit_ids = joins(:active_ranges).merge(Hmis::ActiveRange.active_on(date)).pluck(:id)

    where(id: active_unit_ids)
  end

  # Filter scope
  scope :with_status, ->(statuses) do
    return unoccupied_on(Date.current) if statuses == ['AVAILABLE']
    return occupied_on(Date.current) if statuses == ['FILLED']

    self
  end

  # Filter scope
  scope :with_unit_type, ->(unit_type_ids) { where(unit_type_id: unit_type_ids) }

  def self.apply_filters(input)
    Hmis::Filter::UnitFilter.new(input).filter_scope(self)
  end

  def occupied?
    unit_occupancies.active_on(Date.current).exists?
  end

  def occupant_names
    unit_occupancies.active_on(Date.current).
      joins(:client).
      pluck(c_t[:first_name], c_t[:last_name]).
      map { |n| n.compact.join(' ') }
  end

  def occupants_on(date = Date.current)
    enrollment_ids = unit_occupancies.active_on(date).pluck(:enrollment_id)
    Hmis::Hud::Enrollment.where(id: enrollment_ids)
  end
  alias occupants occupants_on

  def start_date
    Hmis::ActiveRange.most_recent_for_entity(self)&.start_date
  end

  def end_date
    Hmis::ActiveRange.most_recent_for_entity(self)&.end_date
  end

  def to_pick_list_option
    { code: id, label: name, secondary_label: unit_type&.description }
  end
end
