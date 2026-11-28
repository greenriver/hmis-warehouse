###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  # Copies HMIS form definitions and the configuration they depend on between installations.
  # See docs/features/hmis/hmis-form-transfer.md.
  module FormTransfer
    FORMAT_VERSION = 3
    READABLE_FORMAT_VERSIONS = [2, 3].freeze

    def self.default_data_source_id
      GrdaWarehouse::DataSource.hmis.sole.id
    end

    # Mirrors Hmis::Form::CustomDataElementGenerator#determine_owner_type
    def self.cded_owner_type(item, definition)
      record_type = item.dig('mapping', 'record_type')
      owner_type = record_type ? Hmis::Form::RecordType.find(record_type).owner_type : definition.owner_class.sti_name
      return owner_type unless owner_type == 'Hmis::Hud::HmisService'

      definition.identifier == 'service' ? 'Hmis::Hud::Service' : 'Hmis::Hud::CustomService'
    end

    def self.file_tag_columns
      GrdaWarehouse::AvailableFileTag.column_names - ['id', 'created_at', 'updated_at']
    end

    # A unit with no active range counts as active, so ranges are part of what makes two units identical.
    def self.active_range_signature(unit)
      unit.active_ranges.sort_by(&:start_date).map do |range|
        { 'start_date' => range.start_date.iso8601, 'end_date' => range.end_date&.iso8601 }
      end
    end
  end
end
