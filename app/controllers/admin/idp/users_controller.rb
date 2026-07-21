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

      # don't let users set these params from the form. expired_at has no IdP-side equivalent to
      # push, so it always stays local-only. Identity fields are stripped only when the profile is
      # locked (the IdP service can't accept writes); when it can, they flow through and get synced.
      private def idp_managed_param_keys
        keys = [:expired_at]
        keys += [:first_name, :last_name, :email] if @user&.profile_managed_by_idp?
        keys
      end

      # After the shared local `active: false` flip commits, disable the account in the IdP.
      private def push_deactivate_to_idp
        with_idp_soft_failure("Local access revoked, but couldn't disable #{@user.name} in the identity provider") do
          @user.idp_deactivate!
        end
      end

      # After the shared local save commits, push any first_name/last_name/email change to the IdP.
      # No-ops when the user's IdP service doesn't accept profile writes (form disables those
      # inputs in that case, so user_params wouldn't carry a change anyway).
      private def push_profile_update_to_idp
        changes = @user.saved_changes.slice('first_name', 'last_name', 'email')
        return if changes.empty?

        attributes = changes.transform_values(&:last).symbolize_keys
        with_idp_soft_failure("Local changes saved, but couldn't sync profile to #{@user.name}'s identity provider record") do
          @user.idp_update_profile!(attributes)
        end
      end
    end
  end
end
