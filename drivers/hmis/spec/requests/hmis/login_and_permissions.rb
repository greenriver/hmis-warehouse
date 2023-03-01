def hmis_login(user)
  post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
end

def assign_viewable(access_group, viewable, user)
  # TODO: This is to prevent having to change all the tests now that we have
  # Hmis::GroupViewableEntity, which has different association types. We should
  # change the tests once we finish that thought, but it felt like we should
  # make a decision about it before changing all the tests
  viewable = Hmis::Hud::Project.find_by(id: viewable.id) if viewable.is_a? GrdaWarehouse::Hud::Project
  viewable = Hmis::Hud::Organization.find_by(id: viewable.id) if viewable.is_a? GrdaWarehouse::Hud::Organization
  viewable = GrdaWarehouse::DataSource.find_by(id: viewable.id) if viewable.is_a? GrdaWarehouse::DataSource

  access_group.add_viewable(viewable)
  role = Hmis::Role.first || create(:hmis_role)
  access_group.access_controls.create(role: role) if access_group.access_controls.empty?
  access_group.access_controls.first.add(user)
end

def remove_viewable(access_group, viewable, user)
  access_group.remove_viewable(viewable)
  access_group.access_controls&.first&.remove(user)
end
