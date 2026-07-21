###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    # Admin-initiated, IdP-backed account provisioning shared by the warehouse and HMIS admin
    # user controllers. Given a chosen connector and identity fields, Idp::AdminUserCreator
    # provisions (or links) the remote account and persists the local user; the admin then
    # assigns access on the edit form. Each including controller supplies the user class,
    # post-create destination, and next-step wording via the template methods below.
    module UserCreation
      extend ActiveSupport::Concern
      include ::Admin::Idp::SoftFailure

      included do
        before_action :require_user_creation_available!, only: [:new, :create]
        before_action :set_connectors, only: [:new, :create]
        helper_method :idp_user_creation_available?
      end

      def new
        @user = creation_user_class.new
      end

      def create
        @user = ::Idp::AdminUserCreator.call(
          connector_id: create_connector_id,
          email: new_user_params[:email],
          first_name: new_user_params[:first_name],
          last_name: new_user_params[:last_name],
          user_class: creation_user_class,
        )
      rescue ActiveRecord::RecordInvalid => e
        @user = e.record
        flash.now[:error] = 'Please review the form problems below'
        render :new
      rescue ::Idp::ServiceError => e
        @user = creation_user_class.new(new_user_params.except(:connector_id))
        flash.now[:error] = "Couldn't create the account in the identity provider: #{e.message}"
        render :new
      else
        emailed = with_idp_soft_failure("Account created, but the setup email couldn't be sent to #{@user.email}") do
          @user.idp_send_account_setup_email!
        end
        redirect_to after_user_creation_path(@user), notice: creation_notice(@user, emailed: emailed)
      end

      # Where to send the admin after a successful create — the edit form, to assign access.
      private def after_user_creation_path(user)
        edit_admin_user_path(user)
      end

      # The user class to provision. HMIS overrides with Hmis::User (same table, different mapping).
      private def creation_user_class
        User
      end

      # Index to redirect to when creation isn't available for this deployment.
      private def user_index_path
        admin_users_path
      end

      private def creation_notice(user, emailed:)
        parts = ["Account created for #{user.email}."]
        parts << 'A setup email has been sent.' if emailed
        parts << creation_next_step_message
        parts.join(' ')
      end

      # Trailing instruction pointing the admin at the access UI on the edit form.
      private def creation_next_step_message
        'Assign roles and access below.'
      end

      # Active configs whose IdP can provision new accounts. A deployment may have several
      # (one per realm), so the create form lets the admin choose when there is more than one.
      # Empty under Devise: provisioning routes through the IdP and relies on Idp::Support, which
      # is only mixed into the user models under AuthMethod.jwt?.
      private def available_connectors
        return [] unless AuthMethod.jwt?

        @available_connectors ||= ::Idp::ServiceConfig.active.order(:name, :id).select do |config|
          config.to_service.supports_user_creation?
        rescue ::Idp::ServiceError
          false
        end
      end

      private def idp_user_creation_available?
        available_connectors.any?
      end

      private def require_user_creation_available!
        return if idp_user_creation_available?

        redirect_to user_index_path, alert: 'Creating user accounts is not available for this identity provider.'
      end

      private def set_connectors
        @connectors = available_connectors
      end

      # The connector to provision into: the admin's choice when offered, otherwise the sole
      # available connector. Constrained to available connectors so the param can't target an
      # arbitrary or creation-incapable config.
      private def create_connector_id
        chosen = new_user_params[:connector_id]
        ids = available_connectors.map(&:connector_id)
        return chosen if chosen.present? && ids.include?(chosen)

        ids.first
      end

      private def new_user_params
        params.require(:user).permit(:first_name, :last_name, :email, :connector_id)
      end
    end
  end
end
