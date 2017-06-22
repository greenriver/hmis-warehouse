class ConvertHanReleaseToHousingRelease < ActiveRecord::Migration
  def up
    full_releases = GrdaWarehouse::Hud::Client.destination.where.not(housing_assistance_network_released_on: nil).pluck(:id)
    puts "Converting #{full_releases.size} HAN release dates to full releases"
    GrdaWarehouse::Hud::Client.paper_trail.disable
    full_releases.each do |id|
      client = GrdaWarehouse::Hud::Client.destination.find(id)
      client.update(housing_release_status: 'Full HAN Release')
    end
    GrdaWarehouse::Hud::Client.paper_trail.enable
  end
end
