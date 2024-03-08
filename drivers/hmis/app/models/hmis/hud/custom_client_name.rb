###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomClientName" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomClientName < Hmis::Hud::Base
  self.table_name = :CustomClientName
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  self.ignored_columns += [:search_name_full, :search_name_last]
  has_paper_trail(meta: { client_id: ->(r) { r.client&.id } })

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
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :active_range, class_name: 'Hmis::ActiveRange', as: :entity, dependent: :destroy
  alias_to_underscore [:NameDataQuality, :CustomClientNameID, :PersonalID]

  scope :primary_names, -> { where(primary: true) }

  scope :active, ->(date = Date.current) do
    left_outer_joins(:active_range).where(Hmis::ActiveRange.arel_active_on(date))
  end

  # hide previous declaration of :viewable_by, we'll use this one
  replace_scope :viewable_by, ->(user) do
    joins(:client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def primary?
    !!primary
  end

  def full_name
    [first, middle, last, suffix].compact.join(' ')
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

  def equal_for_merge?(other)
    columns = [:first, :last, :middle, :suffix, :use]
    columns.all? do |col|
      send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
    end
  end
end
