###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::Idp::InactiveUsersController < ApplicationController
  include ::Admin::Concerns::InactiveUserManagementBehavior
  include ::Admin::Idp::SoftFailure

  def _prefixes
    @_prefixes ||= [self.class.controller_path, 'admin/inactive_users'] + ApplicationController._prefixes
  end

  private def reactivate_user!
    # paper_trail.update_columns() allows us to update the user even if the record is invalid,
    # while still recording a version (plain update_columns bypasses PaperTrail's callbacks entirely)
    @user.paper_trail.update_columns(active: true, last_activity_at: Time.current, expired_at: nil)
    with_idp_soft_failure("Local access restored, but couldn't re-enable #{@user.name} in the identity provider") do
      @user.idp_reactivate!
    end
  end
end
