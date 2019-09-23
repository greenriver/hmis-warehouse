###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::HmisClient < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  has_one :destination_client, through: :client
  serialize :case_manager_attributes, Hash
  serialize :assigned_staff_attributes, Hash
  serialize :counselor_attributes, Hash
  serialize :outreach_counselor_attributes, Hash

  scope :consent_active, -> do
    where(
      arel_table[:consent_confirmed_on].lteq(Date.current).
      and(arel_table[:consent_expires_on].gteq(Date.current))
    )
  end

  scope :consent_inactive, -> do
    where.not(id: consent_active.select(:id))
  end

  def address_lat_lon
    return nil unless last_permanent_zip.present?
    begin
      result = Nominatim.search(last_permanent_zip).country_codes('us').first
      if result.present?
        return {address: last_permanent_zip, lat: result.lat, lon: result.lon, boundingbox: result.boundingbox}
      end
    rescue
      setup_notifier('NominatimWarning')
      @notifier.ping("Error contacting the OSM Nominatim API") if @send_notifications
    end
    return nil
  end

  def last_permanent_zip
    processed_fields.try(:[], 'hud_last_permanent_zip')
  end

  def self.maintain_client_consent
    return unless GrdaWarehouse::Config.get(:release_duration) == 'Use Expiration Date'
    GrdaWarehouse::Hud::Client.revoke_expired_consent
    # all active consent gets a full release
    self.consent_active.preload(:destination_client).find_each do |hmis_client|
      d_client = hmis_client.destination_client
      d_client.consent_form_signed_on = hmis_client.consent_confirmed_on
      d_client.consent_expires_on = hmis_client.consent_expires_on
      d_client.housing_release_status = d_client.class.full_release_string
      d_client.save if d_client.changed?
    end
  end

  def self.maintain_sexual_orientation(connection_key:, cdid:, site_id:)
    api = EtoApi::Detail.new(trace: false, api_connection: connection_key)
    options = api.demographic_defined_values(cdid: cdid, site_id: site_id).map do |m|
      [m['ID'], m['Text']]
    end.to_h

    self.where(sexual_orientation: nil).find_each do |hmis_client|
      value = JSON.parse(hmis_client.response).try(:[], 'CustomDemoData')&.select{|m| m['CDID'] == cdid}&.first&.try(:[], 'value')
      hmis_client.update(sexual_orientation: options[value])
    end
  end
end