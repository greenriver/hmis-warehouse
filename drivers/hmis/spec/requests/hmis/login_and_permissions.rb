def hmis_login(user)
  post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
end

def assign_viewable(access_group, viewable, user)
  access_group.add_viewable(viewable)
  access_group.add(user)
end
