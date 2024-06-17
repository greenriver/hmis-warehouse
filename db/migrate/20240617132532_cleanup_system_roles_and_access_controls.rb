class CleanupSystemRolesAndAccessControls < ActiveRecord::Migration[7.0]
  # Cleanup a bug in the system scope on Role
  def up
    [
      'System Role - Can Edit Project Groups',
      'System Role - Can Participate in Cohorts',
      'System Role - Can View Cohorts',
    ].each do |name|
      keep_id = Role.where(name: name, system: true).minimum(:id)
      delete_ids = Role.where(name: name, system: true).where.not(id: keep_id).pluck(:id)
      # Find the unique access controls based on collection_id, and user_group_id that use the
      # roles in deleted_ids.
      # Keep the first of each of those, updating the role_id to be keep_id, unless one already exists
      # using role_id: keep_id
      # Remove any Access Controls that use delete_ids
      combinations = {}
      AccessControl.where(role_id: delete_ids).find_each do |ac|
        combinations[[ac.collection_id, ac.user_group_id]] ||= []
        combinations[[ac.collection_id, ac.user_group_id]] << ac
      end
      combinations.each do |(collection_id, user_group_id), access_controls|
        # We already have one that uses the role we want to keep
        next if access_controls.any? { |ac| ac.role_id == keep_id }

        puts "Found #{access_controls.count} Access Controls that should have been using the role #{keep_id}"
        access_controls.min_by(&:id).update!(role_id: keep_id)
      end
      AccessControl.where(role_id: delete_ids).destroy_all
      Role.where(id: delete_ids).each(&:destroy!)
    end

    # Cleanup any exact duplicate Access Controls (this is probably just a side-effect of running the
    # migration a bunch of times, but there's no harm making sure)
    controls = AccessControl.system.group_by { |ac| [ac.collection_id, ac.user_group_id, ac.role_id] }
    controls.each do |(collection_id, user_group_id, role_id), access_controls|
      next if access_controls.count == 1

      # Keep the one with the lowest ID
      access_controls.sort_by(&:id).drop(1).each(&:destroy!)
    end


    # Fix the collection type on collections that are confused
    Collection.system.find_each do |collection|
      types = collection.group_viewable_entities.distinct.pluck(:entity_type)
      next if types.count > 1

      collection_type = case types.first
      when 'GrdaWarehouse::ProjectGroup'
        'Project Groups'
      when 'GrdaWarehouse::Cohort'
        'Cohorts'
      when 'GrdaWarehouse::DataSource', 'GrdaWarehouse::Hud::Organization', 'GrdaWarehouse::Hud::Project'
        'Projects'
      end
      collection.update!(collection_type: collection_type)
    end
  end
end
