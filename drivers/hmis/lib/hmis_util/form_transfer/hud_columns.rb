###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Columns copied for each HUD record: the HUD CSV columns, minus the ones that describe the
    # source system, plus HMIS-only columns the UI shows.
    module HudColumns
      SKIPPED = ['UserID', 'DateDeleted', 'ExportID'].freeze
      EXTRAS = {
        'Hmis::Hud::Organization' => ['confidential', 'description', 'contact_information'],
        'Hmis::Hud::Project' => ['confidential', 'description', 'contact_information'],
      }.freeze
      PROJECT_CHILDREN = {
        'funders' => 'Hmis::Hud::Funder',
        'project_cocs' => 'Hmis::Hud::ProjectCoc',
        'inventories' => 'Hmis::Hud::Inventory',
      }.freeze

      def self.for(klass)
        klass.hud_csv_headers.map(&:to_s) - SKIPPED + EXTRAS.fetch(klass.name, [])
      end

      # The app's Time#to_json writes a display format that drops seconds, so dates and times are
      # written as ISO 8601 strings.
      def self.slice(record)
        record.slice(*self.for(record.class)).transform_values do |value|
          case value
          when Time, ActiveSupport::TimeWithZone then value.iso8601(6)
          when Date then value.iso8601
          else value
          end
        end
      end
    end
  end
end
