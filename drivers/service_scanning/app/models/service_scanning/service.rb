###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class Service < GrdaWarehouseBase
    include ArelHelper

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :user, optional: true

    scope :bed_night, -> do
      where(type: 'ServiceScanning::BedNight')
    end

    scope :outreach, -> do
      where(type: 'ServiceScanning::Outreach')
    end

    scope :bed_nights_or_outreach, -> do
      where(type: ['ServiceScanning::BedNight', 'ServiceScanning::Outreach'])
    end

    def self.bed_nights_or_outreach_with_extrapolated
      bed_nights = bed_night&.preload(project: :organization)&.group_by { |m| m.provided_at.to_date }
      outreach = outreach&.preload(project: :organization)&.group_by { |m| m.provided_at.to_date }
      extrapolated_dates = Set.new
      if outreach
        outreach.each_key do |date|
          extrapolated_dates += (date.beginning_of_month..date.end_of_month).to_a
        end
        extrapolated_dates -= outreach.keys if outreach
        extrapolated = extrapolated_dates.map do |date|
          [
            date,
            [ServiceScanning::ExtrapolatedOutreach.new(provided_at: date.to_time)],
          ]
        end.to_h
      end
      all_dates = {}
      days = bed_nights.keys if bed_nights
      days += outreach.keys if outreach
      days += extrapolated_dates.to_a if extrapolated_dates
      days.uniq.sort.each do |date|
        records = []
        records += bed_nights[date] if bed_nights && bed_nights[date]
        records += outreach[date] if outreach && outreach[date]
        records += extrapolated[date] if extrapolated && extrapolated[date]
        all_dates[date] = records.compact
      end
      all_dates
    end

    attr_accessor :scanner_id, :slug, :service_note

    validates_presence_of :project_id

    def self.project_options_for_select(user:)
      # ::GrdaWarehouse::Hud::Project.options_for_select(user: user)
      # Don't delegate this to project since we want a limited set and
      # the user may not have "access" to the project
      project_type_column = ::GrdaWarehouse::Hud::Project.project_type_column
      options = {}
      project_scope = ::GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(::GrdaWarehouse::DataSource.scannable)
      project_scope = project_scope.viewable_by(user)
      project_scope = project_scope.merge(::GrdaWarehouse::Hud::Project.non_confidential) unless user&.can_view_confidential_enrollment_details?
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

    def title_only
      title
    end
  end
end
