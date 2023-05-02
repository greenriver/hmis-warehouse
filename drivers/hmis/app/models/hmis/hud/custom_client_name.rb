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

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_attribute :name_data_quality, :NameDataQuality
  alias_attribute :custom_client_name_id, :CustomClientNameID

  scope :primary_names, -> { where(primary: true) }

  scope :active, ->(date = Date.today) do
    left_outer_joins(:active_range).where(ar_t[:end].eq(nil).or(ar_t[:end].gteq(date)))
  end

  # hide previous declaration of :viewable_by, we'll use this one
  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def self.primary
    primary_names.first
  end

  def self.hud_key
    :CustomClientNameID
  end

  def self.use_values
    USE_VALUES
  end
end
