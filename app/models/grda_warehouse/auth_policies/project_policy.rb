class GrdaWarehouse::AuthPolicies::ProjectPolicy
  attr_reader :user

  def initialize(user:, project_ids:)
    @user = user
    @project_ids = project_ids
  end

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      permitted_project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: permission)
      (permitted_project_ids & @project_ids).any?
    end
  end
end
