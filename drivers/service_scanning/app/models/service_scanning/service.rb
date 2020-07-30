###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class Service < GrdaWarehouseBase
    include ArelHelper

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :user

    attr_accessor :scanner_id, :slug

    validates_presence_of :project_id

    def self.project_options_for_select(_user:)
      # ::GrdaWarehouse::Hud::Project.options_for_select(user: user)
      # Don't delegate this to project since we want a limited set and
      # the user may not have "access" to the project
      project_type_column = ::GrdaWarehouse::Hud::Project.project_type_column
      options = {}
      project_scope = ::GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(::GrdaWarehouse::DataSource.scannable)
      project_scope.
        joins(:organization).
        order(o_t[:OrganizationName].asc, ProjectName: :asc).
        pluck(o_t[:OrganizationName].as('org_name'), :ProjectName, project_type_column, :id).each do |org, project_name, project_type, id|
          options[org] ||= []
          options[org] << ["#{project_name} (#{HUD.project_type_brief(project_type)})", id]
        end
      options
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
      ServiceScanning::Service.distinct.pluck(:other_type).map(&:presence).compact.sort
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
