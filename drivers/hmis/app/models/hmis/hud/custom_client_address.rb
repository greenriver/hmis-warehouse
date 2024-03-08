###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomClientAddress" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomClientAddress < Hmis::Hud::Base
  self.table_name = :CustomClientAddress
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  has_paper_trail(
    meta: {
      client_id: ->(r) { r.client&.id },
      enrollment_id: ->(r) { r.enrollment&.id },
      project_id: ->(r) { r.enrollment&.project&.id },
    },
  )

  USE_VALUES = [
    :home,
    :work,
    :school,
    :temp,
    :old,
    :mail,
  ].freeze

  TYPE_VALUES = [
    :postal,
    :physical,
    :both,
  ].freeze

  # enrollment_address_type that specifies in what capacity is this address related to the EnrollmentID. May either null
  # or 'move_in' but could incorporate other types in the future (address at exit, or prior address at intake etc)
  ENROLLMENT_TYPES = [
    ENROLLMENT_MOVE_IN_TYPE = 'move_in'.freeze,
  ].freeze
  validates :enrollment_address_type, presence: { in: ENROLLMENT_TYPES }, allow_nil: true

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:AddressID, :PersonalID, :UserID, :EnrollmentID]

  validates_presence_of :EnrollmentID, if: :enrollment_address_type

  scope :active, ->(date = Date.current) do
    left_outer_joins(:active_range).where(Hmis::ActiveRange.arel_active_on(date))
  end

  scope :move_in, -> do
    where(enrollment_address_type: ENROLLMENT_MOVE_IN_TYPE).where.not(EnrollmentID: nil)
  end

  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def equal_for_merge?(other)
    columns = [
      :city,
      :country,
      :district,
      :line1,
      :line2,
      :postal_code,
      :state,
    ]

    columns.all? do |col|
      send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
    end
  end

  def type
    address_type
  end

  def enrollment_move_in_type?
    enrollment_address_type == ENROLLMENT_MOVE_IN_TYPE
  end

  def self.hud_key
    :AddressID
  end

  def self.use_values
    USE_VALUES
  end

  def self.type_values
    TYPE_VALUES
  end

  def validate_required_fields?
    enrollment_move_in_type?
  end

  USA_STATES = ['AK', 'AL', 'AR', 'AS', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'GU', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MP', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VI', 'VT', 'WA', 'WI', 'WV', 'WY'].freeze
  with_options(if: :validate_required_fields?) do
    validates :line1, presence: true
    validates :city, presence: true
    validates :state, inclusion: { in: USA_STATES, message: 'is not a valid US state' }
    validates :postal_code, presence: true, format: { with: /\A\d{5}/, message: 'should be a valid ZIP Code' }
  end
end
