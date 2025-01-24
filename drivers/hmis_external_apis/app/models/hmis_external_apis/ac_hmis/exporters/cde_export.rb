###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis::AcHmis::Exporters
  class CdeExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter
    include ::Hmis::Concerns::HmisArelHelper

    UNIT_TYPE_KEY = 'unit_type'.freeze
    AUTO_EXIT_KEY = 'auto_exit'.freeze

    def run!
      Rails.logger.info 'Generating CDE report'
      write_row(columns)
      total = cdes.count
      Rails.logger.info "There are #{total} CDEs to export"

      cdes.each.with_index do |cde, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?

        owner_id = cde.owner_id
        owner_id = client_id_to_warehouse_id[owner_id] if cde.data_element_definition.owner_type == 'Hmis::Hud::Client'
        # Skip if there is no owner ID. Could happen if client doesn't have a destination client yet.
        next unless owner_id

        values = [
          cde.id,
          cde.data_element_definition.key,
          cde.data_element_definition.owner_type.demodulize,
          owner_id,
          cde.value,
          cde.date_created,
          cde.date_updated,
        ]
        write_row(values)
      end

      # Include Unit Type assignment for all Enrollments at Walk-in projects
      write_unit_occupancies
      # Include Auto Exit flag for auto-exited Enrollments
      write_auto_exits
    end

    private

    def columns
      [
        'ResponseID',
        'CustomFieldKey',
        'RecordType',
        'RecordId',
        'Response',
        'DateCreated',
        'DateUpdated',
      ]
    end

    def cdes
      @cdes ||= Hmis::Hud::CustomDataElement.
        where(data_source: data_source).
        joins(:data_element_definition).
        # Exclude some Custom Data Elements that are exported in other files. It would be simpler to
        # just export them here, but customer prefers to keep dedicated file (which was added first).
        where.not(data_element_definition: { key: HmisExternalApis::AcHmis::Exporters::CdedExport::EXCLUDED_CUSTOM_DATA_ELEMENT_KEYS }).
        preload(:data_element_definition)
    end

    def walk_in_cded
      @walk_in_cded ||= Hmis::Hud::CustomDataElementDefinition.where(data_source: data_source, key: :direct_entry, owner_type: 'Hmis::Hud::Project').first!
    end

    # { source client id => destination warehouse id }
    # only includes source clients that are the Owner of any CDEs
    def client_id_to_warehouse_id
      @client_id_to_warehouse_id ||=
        Hmis::Hud::Client.where(data_source: data_source).
          joins(:custom_data_elements).    # Only include clients that have CDEs
          joins(:warehouse_client_source). # Join to Warehouse Client to get destination ID
          pluck(c_t[:id], wc_t[:destination_id]).to_h
    end

    def write_auto_exits
      # Include Auto Exit flag for auto-exited Enrollments
      Hmis::Hud::Enrollment.hmis.auto_exited.preload(:exit).each do |enrollment|
        values = [
          enrollment.exit.id,  # ResponseID
          AUTO_EXIT_KEY,       # CustomFieldKey
          'Enrollment',        # RecordType
          enrollment.id,       # RecordId
          'true',              # Response
          enrollment.exit.auto_exited,  # DateCreated (passing the date that the auto-exit occurred)
          enrollment.exit.DateUpdated,  # DateUpdated
        ]
        write_row(values)
      end
    end

    def write_unit_occupancies
      # Include Unit Type assignment for all Enrollments at Walk-in projects. Even though these are _not_ stored in CustomDataElements.
      project_scope = Hmis::Hud::Project.hmis.where(id: walk_in_cded.values.where(value_boolean: true).pluck(:owner_id))
      seen = Set.new
      unit_occupancies = Hmis::UnitOccupancy.joins(:occupancy_period, enrollment: :project).
        merge(project_scope).
        order(Hmis::ActiveRange.arel_table[:updated_at].asc).
        preload(:occupancy_period, unit: [:unit_type])

      unit_occupancies.each do |unit_occupancy|
        unit_type = unit_occupancy.unit&.unit_type
        next unless unit_type

        enrollment_id = unit_occupancy.enrollment_id
        # If we already wrote a unit type for this enrollment, skip it. The Unit Occupancies
        # are sorted from most recently updated=>oldest, so we should have the correct information.
        # (Note: It is rare that unit occupancy is changed during an enrollment, and even rarer that unit type would change.)
        next if seen.include?(enrollment_id)

        seen.add(enrollment_id)
        values = [
          unit_occupancy.id,                          # ResponseID
          UNIT_TYPE_KEY,                              # CustomFieldKey
          'Enrollment',                               # RecordType
          enrollment_id,                              # RecordId
          unit_type.description,                      # Response
          unit_occupancy.occupancy_period.created_at, # DateCreated
          unit_occupancy.occupancy_period.updated_at, # DateUpdated
        ]
        write_row(values)
      end
    end
  end
end
