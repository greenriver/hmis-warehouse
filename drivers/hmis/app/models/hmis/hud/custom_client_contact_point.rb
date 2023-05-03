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
    :fax,
    :email,
    :pager,
    :url,
    :sms,
    :other,
  ].freeze

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :ContactPointID]

  scope :active, ->(date = Date.today) do
    left_outer_joins(:active_range).where(ar_t[:end].eq(nil).or(ar_t[:end].gteq(date)))
  end

  scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def self.hud_key
    :ContactPointID
  end

  def self.use_values
    USE_VALUES
  end

  def self.syatem_values
    SYSTEM_VALUES
  end
end
