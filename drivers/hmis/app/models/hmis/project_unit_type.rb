###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ProjectUnitType < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_project_unit_type

  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), optional: true

  def self.freshen_project_units
    unit_types_by_external_id = HmisExternalApis::AcHmis::Mper.external_ids
      .where(source_type: Hmis::Unit.sti_name)
      .index_by(&:value)

    scope = preload(:project)
    unit_counts_by_project_and_unit_type_id = Hmis::Unit
      .where(project_id: scope.map { |r| r.project.id })
      .group(:project_id, :unit_type_id)
      .count

    unit_attrs = []
    scope.find_each do |record|
      unit_type = unit_types_by_external_id[record.UnitTypeID]
      next unless local_unit_type_id

      case record.isActive
      when 'Y'
        key = [record.project.id, unit_type.id]
        if unit_counts_by_project_and_unit_type_id[key]
          # If this ProjectID is already mapped to this UnitTypeID in our system, and it is marked as Active=Y, do nothing.
          nil
        else
          # If this ProjectID is not already mapped to this UnitTypeID, add it and add the number of units specified in the UnitCapacity column.
          unit_attrs += record.UnitCapacity.times.map do |i|
            {
              project_id: project.id,
              unit_type_id: unit_type.id,
              unit_size: unit_ty0pe.unit_size,
              name: "Unit #{unit_type.description} #{i + 1}", # FIXME: guess at unit name format
            }
          end
        end
      when 'N'
        # If this ProjectID is already mapped to this UnitTypeID in our system, but it is marked as Active=N, then remove the mapping. At this point also remove any Units for this unit type. Raise if any of those Units are occupied
        existing_units.each(&:destroy)
      else
        raise "unexpected project_unit_type: #{attributes.inspect}"
      end
    end

    Hmis::Unit.import!(unit_attrs)
  end
end
