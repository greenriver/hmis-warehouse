# frozen_string_literal: true

desc 'One time data migration to generate Unit Groups for existing units'
# rails driver:hmis:migrate_unit_groups_20250828
task migrate_unit_groups_20250828: [:environment] do
  Hmis::UnitGroup.transaction do
    OneTimeMigration20250828.new.perform
    # raise ActiveRecord::Rollback # uncomment to test rollback
  end
end

class OneTimeMigration20250828
  def perform
    puts 'Creating unit groups for projects with existing units'

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

    puts "#{projects_without_unit_groups} projects to process"

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
        puts "Processed #{projects_processed} of #{projects_without_unit_groups} projects so far"
      end
    end

    puts "Migration complete!"
    puts "Processed #{projects_processed} projects"
    puts "Created #{unit_groups_created} unit groups"
    puts "Updated #{units_updated} units"
  end
end
