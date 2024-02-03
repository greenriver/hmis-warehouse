###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ClientExternalIdentifierCollection
  attr_accessor :client, :ac_hmis_mci_ids, :warehouse_client_source

  def initialize(client:, ac_hmis_mci_ids:, warehouse_client_source: nil)
    self.client = client
    self.ac_hmis_mci_ids = ac_hmis_mci_ids
    self.warehouse_client_source = warehouse_client_source
  end

  def hmis_identifiers
    [
      {
        type: :client_id,
        identifier: client.id,
        label: 'HMIS ID',
      },
      {
        type: :personal_id,
        identifier: client.personal_id,
        label: 'Personal ID',
      },
      {
        type: :warehouse_id,
        identifier: warehouse_client_source&.destination_id,
        url: warehouse_url,
        label: 'Warehouse ID',
      },
    ]
  end

  def mci_identifiers
    return [] unless HmisExternalApis::AcHmis::Mci.enabled?

    if ac_hmis_mci_ids.present?
      ac_hmis_mci_ids.map do |mci_id|
        {
          type: :mci_id,
          identifier: mci_id.value,
          url: clientview_url(mci_id.value),
          label: 'MCI ID',
        }
      end
    else
      [
        {
          type: :mci_id,
          identifier: nil,
          url: nil,
          label: 'MCI ID',
        },
      ]
    end
  end

  protected

  def warehouse_url
    "https://#{ENV['FQDN']}/clients/#{client.id}/from_source"
  end

  def clientview_url(mci_id_value)
    link_base = HmisExternalApis::AcHmis::Clientview.link_base
    return unless link_base&.present? && mci_id_value&.present?

    "#{link_base}/ClientInformation/Profile/#{mci_id_value}?aid=2"
  end
end
