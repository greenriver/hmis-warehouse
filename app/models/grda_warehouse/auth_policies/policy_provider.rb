require 'memery'

class GrdaWarehouse::AuthPolicies::PolicyProvider
  include Memery
  attr_reader :user

  def initialize(user)
    @user = user
  end

  memoize def for_client(client_or_id)
    client_id = client_id_from_arg(client_or_id)

    user.using_acls? ? client_project_policy(client_id) : legacy_user_role_policy
  end

  protected

  memoize def legacy_user_role_policy
    GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy.new(user: user)
  end

  memoize def client_project_policy(client_id)
    project_ids = GrdaWarehouse::Hud::Enrollment
      .visible_to(user, client_ids: [client_id])
      .joins(:project)
      .pluck(GrdaWarehouse::Hud::Project.arel_table[:id])
      .sort
    return GrdaWarehouse::AuthPolicies::DenyPolicy.instance if project_ids.empty?

    GrdaWarehouse::AuthPolicies::ProjectPolicy.new(user: user, project_ids: project_ids)
  end

  def client_id_from_arg(arg)
    case arg
    when GrdaWarehouse::Hud::Client
      arg.id
    when Integer, String
      arg.to_i
    else
      raise "invalid argument #{arg.inspect}"
    end
  end
end
