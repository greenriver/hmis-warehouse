###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class Location < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    belongs_to :source, polymorphic: true, optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :place, class_name: 'GrdaWarehouse::Place', primary_key: [:lat, :lon], foreign_key: [:lat, :lon], optional: true
    # this relation isn't used; use polymorphic `source` above
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    after_save :fix_source

    def fix_source
      # This somewhat hacky solution gets around the fact that during HMIS Form Processing, we haven't yet saved the
      # Enrollment being generated, so we don't yet have an ID with which to get the Warehouse enrollment.
      return unless source_type.starts_with? 'Hmis::Hud::'

      update_column(:source_type, source_type.sub('Hmis::Hud::', 'GrdaWarehouse::Hud::'))
    end

    def as_point
      [lat, lon]
    end

    def label
      [
        "Seen on: #{located_on}",
        "by #{collected_by}",
      ]
    end

    def as_marker
      {
        lat_lon: as_point,
        label: label,
        date: located_on,
        highlight: false,
      }
    end

    def as_marker_with_name(user)
      name = if user.can_view_clients?
        link_for(client_path(client), client.name)
      else
        client.name
      end
      as_marker.merge(
        client_id: client.id,
        label: [name] + label,
      )
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
  end
end
