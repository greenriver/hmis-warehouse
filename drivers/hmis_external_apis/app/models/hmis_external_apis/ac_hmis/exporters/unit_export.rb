###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  # Class to export Units, including deleted units.
  class UnitExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter
    include ::Hmis::Concerns::HmisArelHelper

    def run!
      Rails.logger.info 'Generating Unit export'
      write_row(columns)
      total = units.count
      Rails.logger.info "There are #{total} Units to export"

      units.each.with_index do |unit, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?
        # Note: expects certain structure because it assumes HmisDataCleanup::MigrateUnitsToUnitGroups20250828 has run.
        # Once #8157 is completed, unit type relationship may be more tightly enforced.
        raise 'unexpected: unit missing unit group' unless unit.unit_group
        raise 'unexpected: unit group missing unit type' unless unit.unit_group.unit_type

        values = [
          unit.id, # UnitID
          unit.unit_group.id, # UnitGroupID
          unit.unit_group.unit_type.description, # UnitTypeName
          unit.project.id, # ProjectID
          unit.project.project_name, # ProjectName
          unit.created_at, # DateCreated
          unit.updated_at, # DateUpdated
          unit.deleted_at, # DateDeleted
        ]
        write_row(values)
      end
    end

    private

    def columns
      [
        'UnitID',
        'UnitGroupID',
        'UnitTypeName',
        'ProjectID',
        'ProjectName',
        'DateCreated',
        'DateUpdated',
        'DateDeleted', # Blank for active units; set when the unit was removed. Deleted units are not reactivated.
      ]
    end

    def units
      @units ||= Hmis::Unit.with_deleted.
        joins(:project).
        merge(Hmis::Hud::Project.where(data_source: data_source)).
        order(Hmis::Hud::Project.arel_table[:id], Hmis::Unit.arel_table[:hmis_unit_group_id], Hmis::Unit.arel_table[:id]).
        preload(:project, unit_group: :unit_type)
    end
  end
end
