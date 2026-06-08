###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  # Exports the full history of unit occupancies, combining hmis_unit_occupancy with hmis_active_ranges.
  # Join keys: UnitID (UnitExport), EnrollmentID (HMIS CSV export, including deleted enrollments).
  # It include unit information because the UnitExport currently does not include deleted units.
  #
  # Note: this was created as a one-off export (Issue#9037), it's not currently part of the daily export process (DataWarehouseUploadJob).
  class UnitOccupancyExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating Unit Occupancy export'
      write_row(columns)
      total = unit_occupancies.count
      Rails.logger.info "There are #{total} unit occupancies to export"

      processed = 0
      unit_occupancies.find_in_batches do |batch|
        occupancy_periods = load_occupancy_periods(batch.map(&:id))
        units = load_units(batch.map(&:unit_id))
        projects = load_projects(units.values.map(&:project_id))

        batch.each do |unit_occupancy|
          Rails.logger.info "Processed #{processed} of #{total}" if (processed % 100).zero?
          processed += 1

          occupancy_period = occupancy_periods[unit_occupancy.id]
          next unless occupancy_period

          unit = units[unit_occupancy.unit_id]
          project = unit && projects[unit.project_id]
          write_row(row_values(unit_occupancy, occupancy_period, unit, project))
        end
      end
    end

    private

    def columns
      [
        'UnitOccupancyID', # Unique ID for this occupancy record
        'UnitID', # Unit identifier; join to Units.csv for active units
        'UnitTypeName', # Unit type; included here because Units.csv omits deleted units
        'ProjectID', # Project identifier; included here because Units.csv omits deleted units
        'ProjectName', # Project name; included here because Units.csv omits deleted units
        'EnrollmentID', # Enrollment identifier; join to Enrollment.csv
        'StartDate', # Date the client entered the unit (often the enrollment entry date)
        'EndDate', # Date the client left the unit (often the exit date), or blank if still active
        'DateCreated', # When the occupancy record was created
        'DateUpdated', # When the occupancy record was last updated
      ]
    end

    def row_values(unit_occupancy, occupancy_period, unit, project)
      [
        unit_occupancy.id,
        unit_occupancy.unit_id,
        unit_type_name(unit),
        project&.id,
        project&.project_name,
        unit_occupancy.enrollment_id,
        occupancy_period.start_date,
        occupancy_period.end_date,
        occupancy_period.created_at,
        occupancy_period.updated_at,
      ]
    end

    def unit_type_name(unit)
      return unless unit

      unit.unit_group&.unit_type&.description || unit.unit_type&.description
    end

    def unit_occupancies
      # Note: need to join with arel to get deleted enrollments
      uo_t = Hmis::UnitOccupancy.arel_table
      e_t = Hmis::Hud::Enrollment.unscoped.arel_table

      @unit_occupancies ||= Hmis::UnitOccupancy.with_deleted.
        joins(uo_t.join(e_t).on(uo_t[:enrollment_id].eq(e_t[:id])).join_sources).
        where(e_t[:data_source_id].eq(data_source.id)).
        order(uo_t[:unit_id], uo_t[:enrollment_id], uo_t[:id])
    end

    def load_occupancy_periods(unit_occupancy_ids)
      Hmis::ActiveRange.with_deleted.
        where(entity_type: Hmis::UnitOccupancy.name, entity_id: unit_occupancy_ids).
        index_by(&:entity_id)
    end

    def load_units(unit_ids)
      Hmis::Unit.with_deleted.
        where(id: unit_ids).
        preload(:unit_type, unit_group: :unit_type).
        index_by(&:id)
    end

    def load_projects(project_ids)
      Hmis::Hud::Project.with_deleted.
        where(id: project_ids).
        index_by(&:id)
    end
  end
end
