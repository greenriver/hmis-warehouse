###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    # JWT-arm admin user management, selected at the route level. The auth-agnostic bulk comes
    # from Admin::Concerns::UserManagementBehavior; this arm carries only the IdP-coupled seams:
    #   - destroy: after the shared local `active: false` flip, push the disable to the IdP.
    #   - expire_password: an IdP UPDATE_PASSWORD required action instead of the Devise reset.
    #   - the 2FA edit/update hooks stay at their no-op default (2FA is IdP-managed).
    # Views fall back to the shared admin/users templates, overriding only the Devise-coupled
    # partials under app/views/admin/idp/users/.
    class UsersController < ApplicationController
      include ::Admin::Concerns::UserManagementBehavior
      include ::Admin::Idp::SoftFailure

      # Fall back to the shared admin/users templates for anything this arm doesn't override:
      # an unqualified lookup (e.g. render 'user_links') finds the idp override first, then the
      # shared template.
      def _prefixes
        @_prefixes ||= [self.class.controller_path, 'admin/users'] + ApplicationController._prefixes
      end

      # The IdP owns credentials, so replace the Devise force-reset with an UPDATE_PASSWORD
      # required action. Best-effort: there is no local state to commit.
      def expire_password
        pushed = with_idp_soft_failure("Couldn't require a password change for #{@user.name} in the identity provider") do
          @user.idp_force_password_change!
        end
        # Unlike deactivate/reactivate there is no authoritative local change here, so only claim
        # success when the IdP push actually landed; on failure with_idp_soft_failure set the warning.
        return redirect_to(action: :index) unless pushed

        redirect_to({ action: :index }, notice: "#{@user.email} will be required to choose a new password on next login.")
      end

      # Params the JWT arm rejects at update (belt-and-suspenders behind the hidden/read-only
      # form inputs): name/email are provisioned from the JWT (Idp::UserProvisioner) and owned
      # by the IdP, and expired_at drives Devise account expiry the IdP does not honor. Dropping
      # them keeps a crafted request from changing them or drifting from the IdP.
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
