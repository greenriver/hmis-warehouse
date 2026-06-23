###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientExternalDataSharing
  extend ActiveSupport::Concern

  EXTERNAL_DATA_SHARING_CDE_KEY = 'exclude_from_external_data_sharing'

  def excluded_from_external_data_sharing?
    defn = self.class.external_data_sharing_cde_definition
    return false unless defn

    Hmis::Hud::CustomDataElement.exists?(
      data_element_definition: defn,
      owner_type: self.class.name,
      owner_id: id,
      value_boolean: true,
    )
  end

  def set_external_data_sharing_exclusion!(value:, user: nil)
    defn = self.class.external_data_sharing_cde_definition
    return unless defn

    cde = Hmis::Hud::CustomDataElement.find_or_initialize_by(
      owner_type: self.class.name,
      owner_id: id,
      data_element_definition: defn,
    )
    cde.assign_attributes(
      value_boolean: value,
      data_source: defn.data_source,
      UserID: user&.id&.to_s || 'system',
    )
    cde.save!
  end

  def external_data_sharing_last_update
    defn = self.class.external_data_sharing_cde_definition
    return unless defn

    cde = Hmis::Hud::CustomDataElement.find_by(
      data_element_definition: defn,
      owner_type: self.class.name,
      owner_id: id,
    )
    return unless cde

    user_name = if cde.UserID == 'system'
      'System'
    else
      User.find_by(id: cde.UserID)&.name || 'System'
    end

    { updated_at: cde.DateUpdated, updated_by: user_name }
  end

  def external_data_sharing_last_update_text
    info = external_data_sharing_last_update
    return unless info

    "Last updated #{I18n.l(info[:updated_at], format: :table_compact)} by #{info[:updated_by]}"
  end

  class_methods do
    def external_data_sharing_cde_definition
      @external_data_sharing_cde_definition ||= Hmis::Hud::CustomDataElementDefinition.find_by(
        key: EXTERNAL_DATA_SHARING_CDE_KEY,
        owner_type: name,
      )
    end
  end
end
