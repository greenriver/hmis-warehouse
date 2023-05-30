###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomClientContactPoint < Hmis::Hud::Base
  self.table_name = :CustomClientContactPoint
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  USE_VALUES = [
    :home,
    :work,
    :temp,
    :old,
    :mobile,
  ].freeze

  SYSTEM_VALUES = [
    :phone,
    # :fax,
    :email,
    # :pager,
    :url, # can be used for whatsapp etc
    # :sms,
    :other, # misc - unsure
  ].freeze

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :ContactPointID]

  scope :active, ->(date = Date.current) do
    left_outer_joins(:active_range).where(ar_t[:end].eq(nil).or(ar_t[:end].gteq(date)))
  end

  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  scope :phones, -> { where(system: :phone) }
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
    columns = [:system, :use, :value]

    columns.all? do |col|
      send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
    end
  end
end
