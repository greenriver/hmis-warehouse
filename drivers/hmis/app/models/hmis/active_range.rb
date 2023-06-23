###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ActiveRange < Hmis::HmisBase
  self.table_name = :hmis_active_ranges
  include ::Hmis::Concerns::HmisArelHelper
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :user, class_name: 'Hmis::User'

  # Some entity types can only have 1 ActiveRange
  UNIQUE_ENTITY_TYPES = [Hmis::UnitOccupancy.name].freeze
  validates_uniqueness_of :entity_id, scope: :entity_type, conditions: -> { where(entity_type: UNIQUE_ENTITY_TYPES) }

  scope :active_on, ->(date = Date.current) do
    # ActiveRange is "active" if the start date is in the past (or today)
    #  AND the end date is in the future (or is nil)
    past_start_date = ar_t[:start_date].lteq(date)
    future_end_date = ar_t[:end_date].eq(nil).or(ar_t[:end_date].gt(date))

    where(past_start_date.and(future_end_date))
  end

  def self.most_recent_for_entity(entity)
    Hmis::ActiveRange.where(entity: entity).order(
      # Prefer nil or later end dates
      ar_t[:end_date].desc.nulls_first,
      # Prefer later start dates
      ar_t[:start_date].desc,
      ar_t[:updated_at].desc,
    ).first
  end

  def active_on(date = Date.current)
    end_date.nil? || end_date > date
  end

  def active?
    active_on
  end
end
