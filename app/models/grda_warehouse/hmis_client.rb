class GrdaWarehouse::HmisClient < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  serialize :case_manager_attributes, Hash
  serialize :assigned_staff_attributes, Hash
  serialize :counselor_attributes, Hash
  serialize :outreach_counselor_attributes, Hash

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
end