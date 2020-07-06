###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class Service < GrdaWarehouseBase

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :user

    attr_accessor :scanner_id, :slug

    def self.project_options_for_select(user:)
      ::GrdaWarehouse::Hud::Project.options_for_select(user: user)
    end

    def self.available_types
      {
        'Bed-Night' => :bed_night,
        'Outreach Contact' => :outreach,
        'Other Service' => :other,
      }
    end

    def self.type_map
      {
        bed_night: ServiceScanning::BedNight,
        outreach: ServiceScanning::Outreach,
        other: ServiceScanning::OtherService,
      }
    end

    def self.type_from_key(key)
      key = key&.to_sym
      return ServiceScanning::BedNight unless type_map.key?(key)

      type_map[key]
    end

    def self.known_other_types
      ServiceScanning::Service.distinct.pluck(:other_type)
    end

    def self.services_by_type_for(client)
      where(client_id: client.id).
        order(provided_at: :desc).
        preload(:project).
        to_a.
        group_by(&:type)
    end
  end
end
