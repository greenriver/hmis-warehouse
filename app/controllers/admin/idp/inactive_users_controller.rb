###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    # JWT-arm inactive-user management, selected at the route level. The auth-agnostic bulk comes
    # from Admin::Concerns::InactiveUserManagementBehavior; this arm carries only the IdP-coupled
    # #reactivate: flip the authoritative local `active` gate, then re-enable the account in the
    # IdP (best-effort). The IdP owns credentials, so there is no random password or reset email.
    class InactiveUsersController < ApplicationController
      include ::Admin::Concerns::InactiveUserManagementBehavior
      include ::Admin::Idp::SoftFailure

      def _prefixes
        @_prefixes ||= [self.class.controller_path, 'admin/inactive_users'] + ApplicationController._prefixes
      end

      def reactivate
        @user = User.inactive.find(params[:id].to_i)
        # update_columns so the authoritative local flip commits even if the record is invalid.
        @user.update_columns(active: true, last_activity_at: Time.current, expired_at: nil)
        with_idp_soft_failure("Local access restored, but couldn't re-enable #{@user.name} in the identity provider") do
          @user.idp_reactivate!
        end
        redirect_to({ action: :index }, notice: "User #{@user.name} re-activated")
      end
    end
  end
end
