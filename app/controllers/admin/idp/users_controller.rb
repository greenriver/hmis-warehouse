###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    class UsersController < ApplicationController
      include ::Admin::Concerns::UserManagementBehavior
      include ::Admin::Idp::SoftFailure

      # Fall back to the shared admin/users templates for any views this arm doesn't override:
      def _prefixes
        @_prefixes ||= [self.class.controller_path, 'admin/users'] + ApplicationController._prefixes
      end

      def expire_password
        pushed = with_idp_soft_failure("Couldn't require a password change for #{@user.name} in the identity provider") do
          @user.idp_force_password_change!
        end
        # Unlike deactivate/reactivate there is no local change here
        return redirect_to(action: :index) unless pushed

        redirect_to({ action: :index }, notice: "#{@user.email} will be required to choose a new password on next login.")
      end

      # don't let users set these params from the form
      private def idp_managed_param_keys
        [:first_name, :last_name, :email, :expired_at]
      end

      # After the shared local `active: false` flip commits, disable the account in the IdP.
      private def push_deactivate_to_idp
        with_idp_soft_failure("Local access revoked, but couldn't disable #{@user.name} in the identity provider") do
          @user.idp_deactivate!
        end
      end
    end
  end
end
