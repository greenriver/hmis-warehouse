###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# exported data from ACHMIS that describes the unit types and capacity for each project (called program)
class Hmis::ProjectUnitTypeMapping < Hmis::HmisBase
  self.table_name = :hmis_project_unit_type_mappings

  belongs_to :project, class_name: 'Hmis::Hud::Project'
  belongs_to :unit_type, class_name: 'Hmis::UnitType'

  scope :active, -> { where(active: true) }

  def self.freshen_project_units(user:, today: Date.current)
    # { [project_id, unit_type_id] => unit_count }
    unit_counts_by_project_and_unit_type_id = Hmis::Unit.group(:project_id, :unit_type_id).count

    scope = preload(:project, :unit_type).order(:id).to_a
    unit_attrs = scope.filter(&:active?).flat_map do |record|
      unit_type = record.unit_type
      project = record.project

      # If this ProjectID is already mapped to this UnitTypeID in our system, and it is marked as Active=Y, do nothing.
      key = [project.id, unit_type.id]
      next if unit_counts_by_project_and_unit_type_id[key]

      # If this ProjectID is not already mapped to this UnitTypeID, add it and add the number of units specified in the UnitCapacity column.
      record.unit_capacity.to_i.times.map do |i|
        {
          project_id: project.id,
          unit_type_id: unit_type.id,
          unit_size: unit_type.unit_size,
          user_id: user.id,
        }
      end
    end
    Hmis::Unit.import!(unit_attrs.compact, validate: false)

    # If this ProjectID is already mapped to this UnitTypeID in our system, but it is marked as Active=N, then remove the mapping. At this point also remove any Units for this unit type. Raise if any of those Units are occupied
    scope.filter(&:inactive?).each do |record|
      existing_units = record.project.units.where(unit_type: record.unit_type)
      raise "Can't remove active units: #{record.inspect}" if existing_units.occupied_on(today).any?

      existing_units.find_each(&:destroy!)
    end
  end

  def inactive?
    !active
  end
end
