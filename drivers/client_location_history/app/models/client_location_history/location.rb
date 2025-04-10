###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

module ClientLocationHistory
  class Location < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    belongs_to :source, polymorphic: true, optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :place, class_name: 'GrdaWarehouse::Place', primary_key: [:lat, :lon], foreign_key: [:lat, :lon], optional: true
    # this relation isn't used; use polymorphic `source` above
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    MARKER_COLOR = '#72A0C1'.freeze

    # Locations where both `lat` and `lon` are present
    scope :valid, -> { where.not(lat: nil).and(where.not(lon: nil)) }

    def lat_lon_present?
      lat.present? && lon.present?
    end

    def as_point
      [lat, lon]
    end

    def as_marker(user = nil, label_attributes = [:seen_on, :collected_by])
      {
        lat_lon: as_point,
        label: label(user, label_attributes),
        date: located_on,
        highlight: false,
      }
    end

    private def label(user, label_attributes)
      raise ArgumentError if label_attributes.include?(:name) && !user

      [
        label_attributes.include?(:name) ? name_for_label(user) : nil,
        label_attributes.include?(:seen_on) ? "Seen on: #{located_at || located_on}" : nil,
        label_attributes.include?(:collected_by) ? "by #{collected_by}" : nil,
      ].compact
    end

    private def name_for_label(user)
      client_name = client.pii_provider(user: user).full_name
      return client_name unless user.can_view_clients?

      # These can be source clients, so make sure any link is going to their destination client
      destination = client
      destination = client.destination_client unless client.destination?
      return client_name unless destination # if no destination client yet, just show name

      link_for(client_path(destination), client_name)
    end

    private def link_for(path, text)
      "<a href=\"#{path}\" target=\"_blank\">#{text}</a>"
    end

    def self.bounds(locations)
      max_lat = locations.maximum(:lat)
      min_lat = locations.minimum(:lat)
      max_lon = locations.maximum(:lon)
      min_lon = locations.minimum(:lon)
      [
        [min_lat, min_lon],
        [max_lat, max_lon],
      ]
    end

    def self.highlight(markers)
      return [] if markers.empty?

      most_recent = markers.max_by { |m| m[:date] }
      most_recent[:highlight] = true
      most_recent[:label] << '<strong>Most-recent contact</strong>'.html_safe
      markers
    end

    include RailsDrivers::Extensions
  end
end
