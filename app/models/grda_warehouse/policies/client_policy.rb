
#
class GrdaWarehouse::Policies::ClientPolicy
  attr_reader :user, :record

  def initialize(user:, record:)
    @user = user
    @record = record
  end

  def can_view_full_dob?
    can?(:can_view_full_dob)
  end

  def can_view_full_ssn?
    can?(:can_view_full_ssn)
  end

  def can_view_client_name?
    can?(:can_view_client_name)
  end

  protected

  def can?(permission)
    project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(user, permission: permission)
    project_id ?  project_ids(permission).include?(project_id) : false
  end
end
