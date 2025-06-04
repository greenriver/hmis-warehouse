###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This is a one-time migration to move any existing Units that don't belong to UnitGroups into new Unit Group.
# The initial UnitGroups are split up by Unit Types.
class HmisDataCleanup::MigrateUnitGroups20250604
  def initialize
  end

  def perform
    Hmis::Hud::Project.transaction do
      Hmis::Hud::Project.hmis.preload(:units).each do |project|
        create_unit_groups_in_project(project)
      end
    end
  end

  def create_unit_groups_in_project(project)
    return if project.units.empty?

    unit_types = project.units.map(&:unit_type_id).uniq

    if unit_types.compact.count > 2
      # Put all units in one UnitGroup called "All Units"
      unit_group = Hmis::UnitGroup.create!(project: project, name: 'All Units')
      project.units.each do |unit|
        unit.update!(unit_group: unit_group)
      end
    else
      # Create a UnitGroup for each unit type
      unit_types.each do |unit_type_id|
        unit_group = Hmis::UnitGroup.create!(
          project: project,
          name: unit_type_names.fetch(unit_type_id, 'Unit Group'),
        )
        # Assign all units of this UnitType to the newly created UnitGroup
        project.units.filter { |u| u.unit_type_id == unit_type_id }.each do |unit|
          unit.update!(unit_group: unit_group)
        end
      end
    end
  end

  def unit_type_names
    @unit_type_names ||= Hmis::UnitType.pluck(:id, :description).to_h
  end
end
