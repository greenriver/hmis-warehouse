
# FIXME
class GrdaWarehouse::ClientAccessPolicy
  attr_reader :user, :project_id

  def initialize(user: nil, project_id:)
    @user = user
  end

  def can_view_full_dob?
    project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: :can_view_full_dob)
    project_ids(permission).include?(project_id)
  end

  def can_view_full_ssn?
    project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: :can_view_full_ssn)
    project_ids(permission).include?(project_id)
  end

  def can_view_client_name?
    project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: :can_view_client_name)
    project_ids(permission).include?(project_id)
  end
end
