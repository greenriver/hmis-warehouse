namespace :group do
  desc "Copy GrdaWarehouse::UserViewableEntity records to user-specific groups"
  task copy_user_viewables: [:environment, "log:info_to_stdout"] do
    GrdaWarehouse::UserViewableEntity.find_each do |viewable|
      user = viewable.user
      entity = viewable.entity
      user.add_viewable(entity) if user.present? && entity.present?
    end
  end

  desc "Create user-specific groups for all users"
  task create_groups: [:environment, "log:info_to_stdout"] do
    User.find_each do |user|
      # This method is private for a reason, but we'll call it here anyway
      group = user.send(:create_access_group)
    end
  end
end
