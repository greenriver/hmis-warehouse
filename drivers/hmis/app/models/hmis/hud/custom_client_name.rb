###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomClientName < Hmis::Hud::Base
  self.table_name = :CustomClientName
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  USE_VALUES = [
    :usual,
    :official,
    :temp,
    :nickname,
    :anonymous,
    :old,
    :maiden,
  ].freeze

  after_save do
    update_client_name if primary?
  end

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :CustomClientNameID, :PersonalID]

  validate :first_or_last_exists

  scope :primary_names, -> { where(primary: true) }

  scope :active, ->(date = Date.current) do
    left_outer_joins(:active_range).where(ar_t[:end].eq(nil).or(ar_t[:end].gteq(date)))
  end

  # hide previous declaration of :viewable_by, we'll use this one
  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def self.first_or_last_required_message
    'Primary name must have a First or Last name'
  end

  private def first_or_last_exists
    return unless primary?

    errors.add(:first, :invalid, full_message: self.class.first_or_last_required_message) unless first.present? || last.present?
  end

  def ==(other)
    columns = [:first, :last, :middle, :suffix, :use]

    columns.all? do |col|
      send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
    end
  end

  def primary?
    !!primary
  end

  def update_client_name
    client.update(
      first_name: first,
      last_name: last,
      middle_name: middle,
      name_suffix: suffix,
      name_data_quality: name_data_quality || 99,
    )
  end

  def self.hud_key
    :CustomClientNameID
  end

  def self.use_values
    USE_VALUES
  end
end
