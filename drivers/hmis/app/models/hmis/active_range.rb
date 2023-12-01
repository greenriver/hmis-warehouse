###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ActiveRange < Hmis::HmisBase
  self.table_name = :hmis_active_ranges
  include ::Hmis::Concerns::HmisArelHelper
  has_paper_trail(
    meta: {
      project_id: ->(r) { r.entity_project_id },
      enrollment_id: ->(r) { r.entity_enrollment_id },
      client_id: ->(r) { r.entity_client_id },
    },
  )

  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :user, class_name: 'Hmis::User'

  # Some entity types can only have 1 ActiveRange
  UNIQUE_ENTITY_TYPES = [Hmis::UnitOccupancy.name].freeze
  validates_uniqueness_of :entity_id, scope: :entity_type, conditions: -> { where(entity_type: UNIQUE_ENTITY_TYPES) }

  scope :active_on, ->(date = Date.current) { where(Hmis::ActiveRange.arel_active_on(date)) }

  def self.arel_active_on(date)
    # ActiveRange is "active" if the start date is in the past (or today)
    #  AND the end date is in the future (or is nil)
    past_start_date = ar_t[:start_date].lteq(date)
    future_end_date = ar_t[:end_date].eq(nil).or(ar_t[:end_date].gt(date))

    past_start_date.and(future_end_date)
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

  def entity_project_id
    case entity_type
    when 'Hmis::Unit'
      entity&.project_id
    when 'Hmis::UnitOccupancy'
      entity&.enrollment&.project&.id
    end
  end

  def entity_enrollment_id
    entity_type == 'Hmis::UnitOccupancy' ? entity&.enrollment&.id : nil
  end

  def entity_client_id
    case entity_type
    when 'Hmis::Hmis::Hud::CustomClientAddress', 'Hmis::Hud::CustomClientContactPoint', 'Hmis::Hud::CustomClientName'
      entity&.client&.id
    when 'Hmis::UnitOccupancy'
      entity&.enrollment&.client&.id
    end
  end

end
