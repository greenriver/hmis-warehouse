###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomClientAddress < Hmis::Hud::Base
  self.table_name = :CustomClientAddress
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  USE_VALUES = [
    :home,
    :work,
    :temp,
    :old,
    :mail,
  ].freeze

  TYPE_VALUES = [
    :postal,
    :physical,
    :both,
  ].freeze

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :AddressID]

  scope :active, ->(date = Date.today) do
    left_outer_joins(:active_range).where(ar_t[:end].eq(nil).or(ar_t[:end].gteq(date)))
  end

  scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def type
    address_type
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
end
