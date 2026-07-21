###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    class InactiveUsersController < ApplicationController
      include ::Admin::Concerns::InactiveUserManagementBehavior
      include ::Admin::Idp::SoftFailure

      def _prefixes
        @_prefixes ||= [self.class.controller_path, 'admin/inactive_users'] + ApplicationController._prefixes
      end

      def reactivate
        @user = User.inactive.find(params[:id].to_i)
        # update_columns so we save even if the record is invalid.
        @user.update_columns(active: true, last_activity_at: Time.current, expired_at: nil)
        with_idp_soft_failure("Local access restored, but couldn't re-enable #{@user.name} in the identity provider") do
          @user.idp_reactivate!
        end
        redirect_to({ action: :index }, notice: "User #{@user.name} re-activated")
      end
    end
  end
end
