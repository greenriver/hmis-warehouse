###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module LoginAndPermissionsSpecHelper
  def hmis_login(user)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  def viewable_type(entity)
    return :projects if entity.is_a? Hmis::Hud::Project
    return :projects if entity.is_a? GrdaWarehouse::Hud::Project
    return :organizations if entity.is_a? Hmis::Hud::Organization
    return :organizations if entity.is_a? GrdaWarehouse::Hud::Organization
    return :data_sources if entity.is_a? GrdaWarehouse::DataSource

    raise "Unsupported entity type: #{entity.class.name}"
  end

  def viewable_hash(entities)
    viewables_h = Hash.new { |hash, key| hash[key] = [] }
    Array.wrap(entities).map { |e| [viewable_type(e), e.id] }.each do |k, v|
      viewables_h[k] << v
    end
    viewables_h
  end

  # Create a new Access Control and assign the user to it.
  # The specified entity or entities (Project/Org/Datasource) are included.
  # If "with_permission" passed, role will only include the permissions passed.
  # If "without_permission" passed, role will include all perms EXCEPT the permissions passed.
  # If neither permission arg passed, role will include all permission.
  def create_access_control(user, entities, with_permission: nil, without_permission: nil, user_group: create(:hmis_user_group))
    # Create role with the correct permissions
    role = if with_permission.present?
      create(:hmis_role_with_no_permissions)
    else
      create(:hmis_role)
    end
    role.update(**Array.wrap(with_permission).map { |p| [p, true] }.to_h) if with_permission.present?
    role.update(**Array.wrap(without_permission).map { |p| [p, false] }.to_h) if without_permission.present?

    # Create data collection
    collection = create(:hmis_access_group, with_entities: entities)

    # Create user group
    user_group.add(user)

    # Create access control
    create(:hmis_access_control, role: role, user_group: user_group, access_group: collection)
  end

  def assign_viewable(access_control, viewable)
    viewable = Hmis::Hud::Project.find_by(id: viewable.id) if viewable.is_a? GrdaWarehouse::Hud::Project
    viewable = Hmis::Hud::Organization.find_by(id: viewable.id) if viewable.is_a? GrdaWarehouse::Hud::Organization

    access_control.access_group.add_viewable(viewable)
  end

  def remove_viewable(access_control, viewable)
    access_control.access_group.remove_viewable(viewable)
  end

  def set_permissions(access_control, value, *permissions)
    access_control.role.update(**permissions.map { |p| [p, value] }.to_h)
  end

  def add_permissions(access_control, *permissions)
    set_permissions(access_control, true, *permissions)
  end

  def remove_permissions(access_control, *permissions)
    set_permissions(access_control, false, *permissions)
  end
end

RSpec.configure do |config|
  config.include LoginAndPermissionsSpecHelper
end
