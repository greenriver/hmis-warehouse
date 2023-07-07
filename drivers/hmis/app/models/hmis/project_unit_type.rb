###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# exported data from ACHMIS that describes the unit types and capacity for each project (called program)
class Hmis::ProjectUnitType < Hmis::HmisBase
  include ::Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_project_unit_types

  belongs_to :project, primary_key: [:data_source_id, :ProjectID], foreign_key: [:data_source_id, :ProgramID], autosave: false, optional: true, class_name: 'Hmis::Hud::Project'

  scope :active, -> { where(IsActive: 'Y') }
  scope :for_project, ->(project) { where(data_source_id: project.data_source_id, ProgramID: project.ProjectID) }

  def self.freshen_project_units(user: )
    # assuming unit types is a small collection
    unit_types_by_external_id = HmisExternalApis::AcHmis::Mper.external_ids
      .preload(:source)
      .where(source_type: Hmis::UnitType.sti_name)
      .index_by(&:value)
      .transform_values(&:source)

    scope = preload(:project)
    unit_counts_by_project_and_unit_type_id = Hmis::Unit
      .where(project_id: scope.map { |r| r.project.id })
      .group(:project_id, :unit_type_id)
      .count

    unit_attrs = []
    scope.find_each do |record|
      unit_type = unit_types_by_external_id[record.UnitTypeID]
      raise "Unit Type not found for mper id #{record.UnitTypeID}" unless unit_type

      case record.IsActive
      when 'Y'
        key = [record.project.id, unit_type.id]
        if unit_counts_by_project_and_unit_type_id[key]
          # If this ProjectID is already mapped to this UnitTypeID in our system, and it is marked as Active=Y, do nothing.
          nil
        else
          # If this ProjectID is not already mapped to this UnitTypeID, add it and add the number of units specified in the UnitCapacity column.
          unit_attrs += record.UnitCapacity.times.map do |i|
            {
              project_id: record.project.id,
              unit_type_id: unit_type.id,
              unit_size: unit_type.unit_size,
              name: "Unit #{unit_type.description} #{i + 1}", # FIXME: guess at unit name format
              user_id: user.id,
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
