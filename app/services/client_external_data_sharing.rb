###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientExternalDataSharing
  EXTERNAL_DATA_SHARING_CDE_KEY = 'exclude_from_external_data_sharing'

  def initialize(client)
    @client = client
  end

  def excluded?
    defn = cde_definition
    return false unless defn

    Hmis::Hud::CustomDataElement.exists?(
      data_element_definition: defn,
      owner_type: @client.class.name,
      owner_id: @client.id,
      value_boolean: true,
    )
  end

  def set_exclusion!(value:, user: nil)
    defn = cde_definition
    return unless defn

    cde = Hmis::Hud::CustomDataElement.find_or_initialize_by(
      owner_type: @client.class.name,
      owner_id: @client.id,
      data_element_definition: defn,
    )
    cde.assign_attributes(
      value_boolean: value,
      data_source: defn.data_source,
      UserID: user&.id&.to_s || User.system_user.id.to_s,
    )
    cde.save!
  end

  def last_update
    defn = cde_definition
    return unless defn

    cde = Hmis::Hud::CustomDataElement.find_by(
      data_element_definition: defn,
      owner_type: @client.class.name,
      owner_id: @client.id,
    )
    return unless cde

    user_name = User.find_by(id: cde.UserID)&.name || 'System'
    { updated_at: cde.DateUpdated, updated_by: user_name }
  end

  def last_update_text
    info = last_update
    return unless info

    "Last updated #{I18n.l(info[:updated_at], format: :table_compact)} by #{info[:updated_by]}"
  end

  def self.cde_definition
    Hmis::Hud::CustomDataElementDefinition.find_by(
      key: EXTERNAL_DATA_SHARING_CDE_KEY,
      owner_type: GrdaWarehouse::Hud::Client.name,
    )
  end

  private

  # Memoized per instance (request-scoped), not at class level.
  def cde_definition
    @cde_definition ||= self.class.cde_definition
  end
end
