class MigrateAccessGroupsToAccessControls < ActiveRecord::Migration[6.1]
  def up
    processed_combinations = Set.new
    unique_user_groups = {}
    AccessGroup.user.each do |access_group|
      unique_user_groups[access_group.associated_entity_set] ||= {
        user_ids: [],
      }
      unique_user_groups[access_group.associated_entity_set][:user_ids] << access_group.user_id
    end
    Role.all.each do |role|
      puts "Processing role: #{role.name}"
      # Move the non-user specific access groups
      AccessGroup.general.each do |access_group|
        puts "Creating access control from general access group: #{access_group.name}"
        # Users that have this role and are in this group
        agm_scope = AccessGroupMember.where(access_group_id: access_group.id)
        ur_scope = UserRole.where(role_id: role.id)
        users = User.where(id: agm_scope.pluck(:user_id)).merge(User.where(id: ur_scope.pluck(:user_id)))
        next unless users.any?

        # Create ACL and add all users to it
        access_control_list = AccessControl.create(role: role, access_group: access_group)
        users.each do |user|
          user.user_access_controls.find_or_create_by(user: user, access_control: access_control_list)
        end
      end
    end

    Role.all.each do |role|
      puts "Processing role for individual users: #{role.name}"
      # Loop through unique_user_groups and see if an existing AccessGroup.general exists with each user that has an entity set that is equal or larger, if found, remove user from batch
      # Loop through and see if an existing AccessGroup.general exists with the same entity set, if found, add users, if not, create AccessGroup with entities
      # Create AccessControl for role we're looking at and the new AccessGroup, add users
      general_access_groups = AccessGroup.general.to_a
      unique_user_groups.each do |entities, data|
        # remove anyone from the users_ids who doesn't have this role
        data[:user_ids] &= UserRole.where(user_id: data[:user_ids], role_id: role.id).pluck(:user_id)
        next unless data[:user_ids].present?

        puts "looking for general access group for user ids: #{data[:user_ids]}"
        general_access_groups.each do |access_group|
          general_entities = access_group.associated_entity_set
          # If the group's entities encompass the user's group's entities, and the user is already in the ACL, don't do anything
          if (entities - general_entities).empty?
            access_control_list_user_ids = AccessControl.find_by(role: role, access_group: access_group)&.user_ids || []
            data[:user_ids] -= access_control_list_user_ids
            puts "Found general access group for user ids: #{access_control_list_user_ids}"
          end
        end

        # Skip to the next group if we've handled all the users
        next unless data[:user_ids].present?

        users = User.where(id: data[:user_ids])
        next unless users

        general_access_groups.each do |access_group|
          puts "looking at general access group: #{access_group.name}"
          general_entities = access_group.associated_entity_set
          # Look for an identical entity set, and add users if it exists
          if entities == general_entities
            puts "Found general access group entity match: #{access_group.name}"
            access_control_list = AccessControl.find_or_create_by(role: role, access_group: access_group)
            access_control_list.add(users)
            # Note that we handled these users and stop processing this set
            data[:user_ids] = []
            break
          end
        end

        # If we haven't handled all the users at this point, create a group for them
        users = User.where(id: data[:user_ids])
        next unless users

        # Create a new group (migrated) and associated ACL and add the remaining users
        ag = AccessGroup.general.create(name: "Migrated User Group: (#{users.map(&:name).join(', ')})")
        puts "No match found, created Access Group: #{ag.name}"
        entities.each do |entity_type, entity_id|
          ag.group_viewable_entities.create(entity_type: entity_type, entity_id: entity_id)
        end
        access_control_list = AccessControl.create!(role: role, access_group: ag)
        access_control_list.add(users)
      end
    end
  end

  def down
    UserAccessControl.destroy_all
    AccessControl.destroy_all
  end
end
