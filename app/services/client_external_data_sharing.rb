###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientExternalDataSharing
  def initialize(client)
    @client = client
  end

  def excluded?
    GrdaWarehouse::ClientAttribute.exists?(
      client_id: @client.id,
      external_data_sharing_exclusion_flag: true,
    )
  end

  def set_exclusion!(value:, user: nil)
    record = GrdaWarehouse::ClientAttribute.find_or_initialize_by(client_id: @client.id)
    record.assign_attributes(
      external_data_sharing_exclusion_flag: value,
      external_data_sharing_updated_by: user&.id || User.system_user.id,
      external_data_sharing_updated_at: Time.current,
    )
    record.save!
  end

  def last_update
    record = GrdaWarehouse::ClientAttribute.find_by(client_id: @client.id)
    return if record.nil? || record.external_data_sharing_exclusion_flag.nil?

    user_name = User.find_by(id: record.external_data_sharing_updated_by)&.name || 'System'
    { updated_at: record.external_data_sharing_updated_at, updated_by: user_name }
  end

  def last_update_text
    info = last_update
    return unless info

    "Last updated #{I18n.l(info[:updated_at], format: :table_compact)} by #{info[:updated_by]}"
  end
end
