###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The `Hmis::Unit` model represents a generic unit of capacity in a project.
# A unit is a resource that can be provided to a household or individual being served by the program.
# Units can represent physical or virtual resources, and their behavior depends on their `variant`.
#
# Note: The term "unit" is intentionally generic and does not exclusively refer to an "apartment unit."
#
# There are four fixed unit variants:
# - **dwelling**: A physical housing unit that may or may not represent a specific dwelling (e.g., a generic "Hotel Room" vs. "Apartment 2B").
# - **shelter**: A physical shelter unit that may or may not represent a specific shelter bed or family shelter capacity.
# - **voucher**: A virtual unit representing a voucher (e.g., a housing voucher).
# - **service_slot**: A virtual unit representing the capacity to provide a service.
#
# This model supports tracking the availability, occupancy, and relationships of units within a project.
# Units can optionally belong to a `UnitGroup`, and may have an associated descriptive `UnitType`.
# Since a Unit may represent physical housing, the same Unit can be occupied, released, and re-occupied over time. (Unlike CE Occupancy records which are "single-use")
class Hmis::Unit < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_units

  has_paper_trail(meta: { project_id: :project_id })

  belongs_to :project, class_name: 'Hmis::Hud::Project'
  belongs_to :unit_group, class_name: 'Hmis::UnitGroup', optional: true

  # Descriptive "type" of this unit (e.g. "3 Bed Room", "Case Management", "Mass Shelter Single")
  belongs_to :unit_type, class_name: 'Hmis::UnitType', optional: true
  # Periods when this unit has been active
  has_many :active_ranges, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  # User that last updated this unit
  belongs_to :user, class_name: 'User'

  # All historical and current occupancies of this unit
  has_many :unit_occupancies, class_name: 'Hmis::UnitOccupancy', inverse_of: :unit, dependent: :destroy
  has_many :active_unit_occupancies, -> { active }, class_name: 'Hmis::UnitOccupancy', inverse_of: :unit
  has_many :current_occupants, through: :active_unit_occupancies, class_name: 'Hmis::Hud::Enrollment', source: :enrollment

  # A unit may have many historical opportunities (which represent past times when this unit was available and then filled)...
  has_many :opportunities, as: :owner, class_name: 'Hmis::Ce::Opportunity', inverse_of: :owner, dependent: :destroy
  # ...but it only has one "latest" opportunity, which could be either:
  # - active and accepting referrals (open),
  # - active with a referral in-progress (locked), or
  # - closed with an accepted referral. This would be prioritized last, after any active opportunity.
  has_one :latest_opportunity, -> { actives_first }, as: :owner, class_name: 'Hmis::Ce::Opportunity', inverse_of: :owner

  # Similarly, a unit may have many historical referrals,
  has_many :referrals, through: :opportunities, class_name: 'Hmis::Ce::Referral'
  # ... but only ONE active referral, which is enforced by the combination of
  # - Hmis::Ce::Opportunity's `unique_opportunity_per_unit` validator, and
  # - Hmis::Ce::Referral's `unique_referral_per_opportunity` validator.
  has_one :active_referral, through: :latest_opportunity, class_name: 'Hmis::Ce::Referral', source: :active_referral

  alias_attribute :date_updated, :updated_at
  alias_attribute :date_created, :created_at

  enum variant: {
    dwelling: 'dwelling',
    voucher: 'voucher',
    service_slot: 'service_slot',
    shelter: 'shelter',
  }
  validates :variant, presence: true, inclusion: { in: variants.keys }

  # Scopes for filtering by unit variant
  scope :dwellings, -> { where(variant: :dwelling) }
  scope :vouchers, -> { where(variant: :voucher) }
  scope :service_slots, -> { where(variant: :service_slot) }
  scope :shelters, -> { where(variant: :shelter) }

  # Scopes for filtering by unit type

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
    units_without_active_range = left_outer_joins(:active_ranges).where(ar_t[:id].eq(nil)).pluck(:id)

    where(id: active_unit_ids + units_without_active_range)
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

  def start_date
    Hmis::ActiveRange.most_recent_for_entity(self)&.start_date
  end

  def end_date
    Hmis::ActiveRange.most_recent_for_entity(self)&.end_date
  end

  def eligibility_requirements
    return unless Hmis::Ce.configuration.enabled? # should have a flag on unit for ce?

    Hmis::Ce::Match::Rule.eligibility_requirement.for_unit(self)
  end

  def priority_scheme
    return unless Hmis::Ce.configuration.enabled? # should have a flag on unit for ce?

    Hmis::Ce::Match::Rule.priority_scheme.for_unit(self).sole # there should only be 1
  end

  # Class method so can use with data loader
  def self.display_name(id:, name: nil, unit_type: nil, variant: nil)
    return name if name.present?
    return "#{unit_type.description} (ID: #{id})" if unit_type.present?
    return "#{variant.to_s.humanize} (ID: #{id})" if variant.present?

    "Unit #{id}"
  end

  def display_name
    self.class.display_name(id: id, name: name, unit_type: unit_type, variant: variant)
  end

  def to_pick_list_option
    { code: id, label: display_name }
  end
end
