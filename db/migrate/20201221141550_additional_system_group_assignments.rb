class AdditionalSystemGroupAssignments < ActiveRecord::Migration[5.2]
  def up
    if Role.permissions.include?(:can_edit_anything_super_user)
      all_data_sources = AccessGroup.where(name: 'All Data Sources').first_or_create
      User.can_edit_anything_super_user.find_each do |user|
        all_data_sources.add(user)
      end

      all_organizations = AccessGroup.where(name: 'All Organizations').first_or_create
      User.can_edit_anything_super_user.find_each do |user|
        all_organizations.add(user)
      end

      all_projects = AccessGroup.where(name: 'All Projects').first_or_create
      User.can_edit_anything_super_user.find_each do |user|
        all_projects.add(user)
      end
    end

    if Role.permissions.include?(:can_manage_cohorts)
      all_cohorts = AccessGroup.where(name: 'All Cohorts').first_or_create
      User.can_manage_cohorts.find_each do |user|
        all_cohorts.add(user)
      end
    end

    if Role.permissions.include?(:can_edit_project_groups)
      all_project_groups = AccessGroup.where(name: 'All Project Groups').first_or_create
      User.can_edit_project_groups.find_each do |user|
        all_project_groups.add(user)
      end
    end
  end
end
