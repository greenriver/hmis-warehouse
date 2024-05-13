
#
class GrdaWarehouse::AuthPolicies::ProjectPolicy
  attr_reader :user

  def initialize(user:, project_id:)
    @user = user
    @project_id = project_id&.to_i
  end

  def client_policy
    @client_policy ||= GrdaWarehouse::Policies::ClientPolicy.new(self)
  end

  protected

  def project_id
    raise 'invalid' unless project_id
    @project_id
  end

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: permission)
      project_ids.include?(project_id)
    end
  end
end
