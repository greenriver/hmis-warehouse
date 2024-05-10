
#
class GrdaWarehouse::AuthPolicies::ProjectPolicy
  attr_reader :user

  def initialize(user:, record:)
    @user = user
    @project_id = case record
      when GrdaWarehouse::Hud::Project
        record.id
      when Integer
        record
      when String
        record.to_i
      end
  end

  def client_policy
    @client_policy ||= GrdaWarehouse::Policies::ClientPolicy.new(self)
  end

  protected

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: permission)
      project_ids(permission).include?(@project_id)
    end
  end
end
