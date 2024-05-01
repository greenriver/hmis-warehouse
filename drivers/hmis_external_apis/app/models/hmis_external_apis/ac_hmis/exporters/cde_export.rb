#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module HmisExternalApis::AcHmis::Exporters
  class CdeExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating CDE report'
      write_row(columns)
      total = cdes.count
      Rails.logger.info "There are #{total} CDEs to export"

      cdes.each.with_index do |cde, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?
        values = [
          cde.id,
          cde.data_element_definition.key,
          cde.data_element_definition.owner_type.demodulize,
          cde.owner_id,
          cde.value,
          cde.date_created,
          cde.date_updated,
        ]
        write_row(values)
      end

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
          'unit_type',                                # CustomFieldKey
          'Enrollment',                               # RecordType
          enrollment_id,                              # RecordId
          unit_type.description,                      # Response
          unit_occupancy.occupancy_period.created_at, # DateCreated
          unit_occupancy.occupancy_period.updated_at, # DateUpdated
        ]
        write_row(values)
      end
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
        preload(:data_element_definition)
    end

    def walk_in_cded
      @walk_in_cded ||= Hmis::Hud::CustomDataElementDefinition.where(data_source: data_source, key: :direct_entry, owner_type: 'Hmis::Hud::Project').first!
    end
  end
end
