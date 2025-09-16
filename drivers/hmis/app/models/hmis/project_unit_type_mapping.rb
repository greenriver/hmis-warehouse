###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# exported data from ACHMIS that describes the unit types and capacity for each project (called program)
class Hmis::ProjectUnitTypeMapping < Hmis::HmisBase
  self.table_name = :hmis_project_unit_type_mappings
  has_paper_trail(meta: { project_id: :project_id })

  belongs_to :project, class_name: 'Hmis::Hud::Project'
  belongs_to :unit_type, class_name: 'Hmis::UnitType'

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def self.freshen_project_units(user:, today: Date.current)
    scope = preload(:project, :unit_type).order(:id)
    # Create initial Units for new Active Project Unit Type Mappings
    create_new_units(scope.active, user: user)
    # Destroy Units for Project Unit Type Mappings that are Inactive
    destroy_inactive_units(scope.inactive, today: today)
  end

  def self.create_new_units(scope, user:)
    # { [project_id, unit_type_id] => unit_count }
    unit_counts_by_project_and_unit_type_id = Hmis::Unit.group(:project_id, :unit_type_id).count

    records_needing_new_units = scope.
      filter { |record| record.project.present? }. # could happen if project was deleted but ProjectUnitTypeMapping wasn't properly cleaned up
      filter do |record|
        # If this ProjectID is already mapped to this UnitTypeID in our system, and it is marked as Active=Y, do nothing (don't import).
        key = [record.project.id, record.unit_type.id]
        !unit_counts_by_project_and_unit_type_id[key]
      end

    return unless records_needing_new_units.any?

    # Collect unit groups to create
    unit_groups_to_create = records_needing_new_units.map do |record|
      {
        project_id: record.project.id,
        unit_type_id: record.unit_type.id,
        name: record.unit_type.description,
      }
    end

    # Batch import unit groups. These probably don't already exist,
    # since we checked that no units exist for this project and unit type.
    # But, it could exist and be empty, so just in case, ignore on conflict.
    Hmis::UnitGroup.import!(unit_groups_to_create, on_duplicate_key_ignore: true)

    # Get unit group IDs and put them in a hash keyed by [project_id, unit_type_id] for lookup when creating units
    unit_groups_by_key = Hmis::UnitGroup.where(project: records_needing_new_units.map(&:project), unit_type: records_needing_new_units.map(&:unit_type)).
      pluck(:project_id, :unit_type_id, :id).
      to_h { |project_id, unit_type_id, id| [[project_id, unit_type_id], id] }

    # Collect units to create
    units_to_create = records_needing_new_units.flat_map do |record|
      project = record.project
      unit_type = record.unit_type

      unit_group_id = unit_groups_by_key[[project.id, unit_type.id]]
      raise "Failed to create unit group for project  #{project.id}, unit_type #{unit_type.id}" unless unit_group_id

      # Create the number of units specified in the UnitCapacity column
      record.unit_capacity.to_i.times.map do
        {
          project_id: project.id,
          unit_type_id: unit_type.id,
          hmis_unit_group_id: unit_group_id,
          unit_size: unit_type.unit_size,
          user_id: user.id,
        }
      end
    end

    # Batch import units
    Hmis::Unit.import!(units_to_create, validate: false)
  end

  def self.destroy_inactive_units(scope, today: Date.current)
    # If this ProjectID is already mapped to this UnitTypeID in our system, but it is marked as Active=N, then remove the mapping.
    # At this point also remove any Units for this unit type. Raise if any of those Units are occupied
    # TODO(#8157) Update to look up by unit-group/unit-type relationship, something like:
    #  record.project.unit_groups.where(unit_type: record.unit_type).each(&:destroy!)
    scope.each do |record|
      existing_units = record.project.units.where(unit_type: record.unit_type)
      raise "Can't remove active units: #{record.inspect}" if existing_units.occupied_on(today).any?

      existing_units.find_each(&:destroy!)
    end
  end

  def inactive?
    !active
  end
end
