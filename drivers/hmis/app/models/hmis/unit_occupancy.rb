###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UnitOccupancy < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_unit_occupancy

  # Unit that is occupied
  belongs_to :unit, class_name: 'Hmis::Unit'
  # Client enrollment that is occupying the unit
  belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment'
  # Date range for which the client occupied the unit.
  has_one :occupancy_period, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  # Service record that relates to this occupancy (likely a BedNight or BedNight-ish custom service)
  belongs_to :hmis_service, class_name: 'Hmis::Hud::HmisService', optional: true

  validates :occupancy_period, presence: true
  delegate :start_date, to: :occupancy_period
  delegate :end_date, to: :occupancy_period

  scope :active, ->(date = Date.today) do
    past_start_date = ar_t[:start_date].lteq(date)
    future_end_date = ar_t[:end_date].eq(nil).or(ar_t[:end_date].gt(date))

    joins(:enrollment, :occupancy_period).where(past_start_date.and(future_end_date))
  end

  scope :for_service_type, ->(service_type_id) do
    joins(:hmis_service).where(hs_t[:custom_service_type_id].eq(service_type_id))
  end

  class << self
    alias active_on active
  end
end
