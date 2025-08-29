# frozen_string_literal: true

desc 'One time data migration to generate Unit Groups for existing units and fix existing unit groups without unit_type'
# rails driver:hmis:migrate_unit_groups_20250828
task migrate_unit_groups_20250828: [:environment] do
  Hmis::UnitGroup.transaction do
    OneTimeMigration20250828.new.perform
    raise ActiveRecord::Rollback # uncomment to test rollback
  end
end

class OneTimeMigration20250828
  def perform
    # First, fix existing unit groups that don't have unit_type set
    add_unit_type_to_unit_groups

    # Then, create unit groups for projects that don't have any yet
    create_unit_groups_for_projects

    puts "Migration complete!"
  end

  private

  def add_unit_type_to_unit_groups
    puts "Fixing existing unit groups without unit_type"

    # Find all unit groups that don't have a unit_type set
    unit_groups_without_type = Hmis::UnitGroup.where(unit_type: nil).includes(:units)

    unit_groups_updated = 0
    warnings_logged = 0

    puts "Found #{unit_groups_without_type.count} unit groups without unit_type"

    unit_groups_without_type.find_each do |unit_group|
      units = unit_group.units.where.not(unit_type: nil)

      if units.empty?
        puts "WARNING: Unit group #{unit_group.id} (#{unit_group.name}) has no units with unit_type"
        warnings_logged += 1
        next
      end

      # Get all distinct unit types for units in this unit group
      unit_type_ids = units.distinct.pluck(:unit_type_id)

      if unit_type_ids.size > 1
        unit_types = Hmis::UnitType.where(id: unit_type_ids).pluck(:description)
        puts "WARNING: Unit group #{unit_group.id} (#{unit_group.name}) has units with different unit types: #{unit_types.join(', ')}"
        warnings_logged += 1
        next
      end

      # All units have the same unit_type, set it on the unit group
      unit_type = Hmis::UnitType.find(unit_type_ids.first)
      unit_group.update!(unit_type: unit_type)
      unit_groups_updated += 1
    end

    puts "Updated #{unit_groups_updated} unit groups"
    puts "#{warnings_logged} warnings logged, needing additional investigation"
  end

  def create_unit_groups_for_projects
    puts "Creating unit groups for projects that have units without groups"

    # Find all project/unit_type combinations that have units but no unit groups
    projects_without_unit_groups = Hmis::Hud::Project.
      joins(:units).
      left_joins(:unit_groups).
      where(hmis_unit_groups: { id: nil }).
      distinct.
      includes(:units)

    projects_processed = 0
    unit_groups_created = 0
    units_updated = 0

    puts "Found #{projects_without_unit_groups.count} projects to process"

    projects_without_unit_groups.find_each do |project|
      # Get all distinct unit types for units in this project
      unit_type_ids = project.units.pluck(:unit_type_id).uniq
      unit_types = Hmis::UnitType.where(id: unit_type_ids)

      unit_types.each do |unit_type|
        # Create a unit group for this unit_type in this project
        unit_group = Hmis::UnitGroup.create!(
          project: project,
          unit_type: unit_type,
          name: "#{unit_type.description}",
        )
        unit_groups_created += 1

        # Update all units of this type in this project to belong to the new unit group
        units_to_update = project.units.where(unit_type: unit_type)
        updated_count = units_to_update.update_all(
          hmis_unit_group_id: unit_group.id
        )
        units_updated += updated_count
      end

      projects_processed += 1

      # Progress reporting every 10 projects
      if projects_processed % 10 == 0
        puts "Processed #{projects_processed} of #{projects_without_unit_groups.count} projects so far"
      end
    end

    puts "Processed #{projects_processed} projects"
    puts "Created #{unit_groups_created} unit groups"
    puts "Updated #{units_updated} units"
  end
end
