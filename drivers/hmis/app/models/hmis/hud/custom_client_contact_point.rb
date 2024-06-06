###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomClientContactPoint" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

# Represents a way to contact a Client (typically by phone or email)
# Based on https://build.fhir.org/datatypes.html#ContactPoint
class Hmis::Hud::CustomClientContactPoint < Hmis::Hud::Base
  self.table_name = :CustomClientContactPoint
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  has_paper_trail(meta: { client_id: ->(r) { r.client&.id } })

  # Based on https://build.fhir.org/valueset-contact-point-use.html
  USE_VALUES = [
    :home,
    :work,
    :school,
    :temp,
    :old,
    :mobile,
  ].freeze

  # Based on https://build.fhir.org/valueset-contact-point-system.html
  SYSTEM_VALUES = [
    :phone, # value is a phone number (for voice or sms)
    :email, # value is an email address
    :url,   # value is not a phone or email and is expressed as a URL. (E.g. Skype, Twitter, Facebook, etc.) Do not use for email addresses.
  ].freeze

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :ContactPointID]

  scope :active, ->(date = Date.current) do
    left_outer_joins(:active_range).where(Hmis::ActiveRange.arel_active_on(date))
  end

  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  scope :with_value, -> { where.not(value: [nil, '']) }
  scope :phones, -> { where(system: :phone) }

  scope :home_phones, -> { phones.where(use: :home) }
  scope :mobile_phones, -> { phones.where(use: :mobile) }
  scope :work_or_school_phones, -> { phones.where(use: [:work, :school]) }
  scope :other_or_unknown_phones, -> { phones.where.not(use: [:home, :mobile, :work, :school]) }

  scope :emails, -> { where(system: :email) }

  def self.hud_key
    :ContactPointID
  end

  def self.use_values
    USE_VALUES
  end

  def self.system_values
    SYSTEM_VALUES
  end

  def equal_for_merge?(other)
    columns = [:system, :value]

    columns.all? do |col|
      send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
    end
  end
end
