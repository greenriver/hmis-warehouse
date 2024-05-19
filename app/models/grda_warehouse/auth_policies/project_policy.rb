###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::ProjectPolicy
  include Memery
  attr_reader :user

  def initialize(user:, project_id:)
    @user = user
    @project_id = project_id
  end

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      permitted_project_ids = user.viewable_project_ids(permission)
      @project_id.in?(permitted_project_ids)
    end
    memoize :"#{permission}?"
  end
end
