# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class UsersController < ApplicationController
    include ViewableEntities # TODO: START_ACL remove when ACL transition complete

    # Valid entity types for AJAX loading. Combines known AccessGroup entity types with coc_codes
    # which is handled separately as it's stored as a JSON array rather than associations.
    VALID_ENTITY_TYPES = (AccessGroup.known_entity_types.map(&:to_s) + ['coc_codes']).freeze

    before_action :require_can_edit_users!, except: [:stop_impersonating]
    before_action :set_user, only: [:edit, :update, :destroy, :impersonate]
    before_action :set_available_idps, only: [:new, :create, :edit]
    before_action :require_can_impersonate_users!, only: [:impersonate]
    after_action :log_user, only: [:show, :edit, :update, :destroy]
    helper_method :sort_column, :sort_direction

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      # TODO: START_ACL replace when ACL transition complete
      # preload(:access_controls, :oauth_identities).
      @users = user_scope.preload(:access_controls, :roles, :oauth_identities)
      # END_ACL

      @users = @users.order(sort_column => sort_direction) if manually_sorted?

      @pagy, @users = pagy(@users)
    end

    def new
      @user = User.new
      ensure_system_contact
      set_system_alerts
      @agencies = Agency.order(:name)
    end

    def create
      @user = User.new(user_params)
      ensure_system_contact
      set_system_alerts
      @agencies = Agency.order(:name)

      connector_id = user_params[:connector_id]

      begin
        User.transaction do
          @user.save!

          # Create user in IDP if connector_id is provided and IDP supports user management
          if connector_id.present?
            idp_service = Idp::ServiceFactory.for_connector(connector_id)
            if idp_service.supports_user_management?
              begin
                result = idp_service.create_user(
                  email: @user.email,
                  first_name: @user.first_name,
                  last_name: @user.last_name,
                  phone: @user.phone,
                )
                if result[:success] && result[:connector_user_id].present?
                  # Create authentication source
                  @user.user_authentication_sources.create!(
                    connector_id: connector_id,
                    connector_user_id: result[:connector_user_id],
                    enabled: true,
                  )
                  @user.update_column(:last_connector_id, connector_id)
                  Rails.logger.info "Created user #{@user.email} in IDP #{connector_id} with ID #{result[:connector_user_id]}"
                end
              rescue Idp::ServiceError => e
                Rails.logger.error "Failed to create user in IDP: #{e.message}"
                # Continue with warehouse user creation even if IDP creation fails
                # User can still be created in warehouse as a shell user
              end
            end
          end
        end
      rescue ActiveRecord::RecordInvalid
        flash[:error] = 'Please review the form problems below'
        render :new
        return
      end

      flash[:notice] = "User #{@user.name} was successfully created."
      redirect_to edit_admin_user_path(@user)
    end

    def edit
      @group = @user.access_group # TODO: START_ACL remove when ACL transition complete
      ensure_system_contact
      set_system_alerts
      # Preload authentication sources to avoid N+1 queries
      @user.user_authentication_sources.load

      # Preload all contacts with their entities and alert definitions for contact relationships display
      @user_contacts = @user.contacts.not_system_contacts.
        active_subscriptions.
        includes(:entity, :alert_definitions).
        order(type: :asc).
        to_a
    end

    def impersonate
      become = User.find(params[:become_id].to_i)
      impersonate_user(become)
      redirect_to root_path
    end

    def stop_impersonating
      stop_impersonating_user
      redirect_to root_path
    end

    def update
      existing_health_roles = @user.health_roles.to_a
      begin
        User.transaction do
          # Associations don't play well with acts_as_paranoid, so manually clean up user ACLs
          @user.user_group_members.where.not(user_group_id: assigned_user_group_ids).destroy_all unless changing_to_acls?

          # TODO: START_ACL remove when ACL transition complete
          # Associations don't play well with acts_as_paranoid, so manually clean up user roles
          if ! user_using_or_changing_to_acls?
            @user.user_roles.where.not(role_id: user_params[:legacy_role_ids]&.select(&:present?)).destroy_all
            @user.access_groups.not_system.
              where.not(id: user_params[:access_group_ids]&.select(&:present?)).each do |g|
                # Don't remove or add system groups
                next if g.system?

                g.remove(@user)
              end
          end
          # END_ACL

          # The User Group data is not captured for update when using the Role-Based view. This means it will not be included
          # in the params when switching from Role-Based permissions to ACLs. In order to prevent wiping out any existing
          # user_group_id data, we need to ignore this param when changing to an ACL based permissions.
          # The reverse is true for the access_group_ids field.
          params_to_update = user_params
          params_to_update = params_to_update.except(:user_group_ids) if changing_to_acls?
          params_to_update = params_to_update.except(:access_group_ids) if changing_to_role_based?
          @user.update!(params_to_update)

          # if we have a user to copy user groups from, add them
          copy_user_groups if user_using_or_changing_to_acls?
          # TODO: START_ACL remove when ACL transition complete
          # Restore any health roles we previously had
          if ! user_using_or_changing_to_acls?
            @user.legacy_roles = (@user.legacy_roles + existing_health_roles).uniq
            @user.set_viewables viewable_params
          end
          # END_ACL
        end
      rescue Exception
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
      end
      # Queue recomputation of external report access
      @user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
      respond_with(@user, location: edit_admin_user_path(@user))
    end

    def search
      search_query = GrdaWarehouse::ClientSearchQuery.find_by(id: params[:id])
      return handle_invalid_query('Search query not found') if search_query.nil?

      search_query.touch
      perform_search(search_query.query_params)
    end

    # Loads select options for entity type dropdowns in the user form via AJAX for lazy loading.
    # This endpoint provides HTML option elements for large entity collections to improve
    # initial page load performance by deferring data loading until needed.
    #
    # @param entity_type [String] The type of entity to load options for. Must be one of:
    #   'data_sources', 'organizations', 'projects', 'project_access_groups',
    #   'coc_codes', 'reports', 'project_groups', 'cohorts'
    # @param base [String] The base parameter name for form inputs, defaults to 'user'
    # @param id [String] Optional user ID when editing existing user to load current selections
    #
    # @return [String] Rendered partial containing HTML option/optgroup elements
    # @return [JSON] Error response with appropriate HTTP status code on failure
    #
    # @example Load project options for new user
    #   GET /admin/users/load_select_options?entity_type=projects&base=user
    # @example Load organization options for existing user
    #   GET /admin/users/load_select_options?entity_type=organizations&base=user&id=123
    #
    # @raise [JSON] 400 Bad Request for invalid/missing entity_type
    # @raise [JSON] 404 Not Found if user ID provided but user doesn't exist
    # @raise [JSON] 500 Internal Server Error for unexpected failures
    #
    # @note This endpoint is protected by require_can_edit_users! before_action
    # @note We explicitly do not have an id as part of the url, it is passed as a param to support new and existing users
    # @see ViewableEntities concern for entity building methods
    def load_select_options
      entity_type = validate_entity_type_param
      return if performed? # Early return if validation failed and response was already rendered

      base = validate_base_param
      @user = load_user_for_entity_options

      begin
        entity = build_entity_options(entity_type, base)
        render partial: 'users/select_options', locals: { entity: entity }
      rescue StandardError => e
        Rails.logger.error "Failed to load select options for #{entity_type}: #{e.message}"
        render json: { error: 'Failed to load options' }, status: :internal_server_error
      end
    end

    # Validates the entity_type parameter for load_select_options endpoint.
    # Ensures the requested entity type is supported and prevents potential security issues
    # from arbitrary entity type values.
    #
    # @return [String] The validated entity type if valid
    # @return [nil] Returns nil and renders JSON error response if invalid
    #
    # @note Renders 400 Bad Request response for invalid/missing entity types
    # @note Valid entity types are: data_sources, organizations, projects,
    #   project_access_groups, coc_codes, reports, project_groups, cohorts
    private def validate_entity_type_param
      entity_type = params[:entity_type]
      valid_entity_types = VALID_ENTITY_TYPES

      unless entity_type.present? && valid_entity_types.include?(entity_type)
        render json: { error: 'Invalid or missing entity type' }, status: :bad_request
        return nil
      end

      entity_type
    end

    # Validates and sanitizes the base parameter for form input naming.
    # The base parameter determines the prefix used for form field names
    # (e.g., 'user[projects][]').
    #
    # @return [String] The sanitized base parameter, defaults to 'user'
    #
    # @note Always returns a safe string value, never nil
    # @note Strips whitespace and falls back to 'user' for empty values
    private def validate_base_param
      base = params[:base]
      return 'user' unless base.present?

      # Sanitize base parameter to prevent potential issues
      base.to_s.strip.presence || 'user'
    end

    # Loads the appropriate User object for entity option building.
    # For existing users, loads the user.
    # For new users, creates a temporary User object for form building.
    #
    # @return [User] The user object (existing or new) for entity option building
    # @return [nil] Returns nil and renders JSON error response if user not found
    #
    # @note For existing users (when params[:id] present), reloads associations
    # @note For new users, returns a new User instance (not persisted)
    # @note Renders 404 Not Found response if user ID provided but user doesn't exist
    private def load_user_for_entity_options
      return User.new if params[:id].blank?

      begin
        User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
        return nil
      end
    end

    # Builds entity options hash for the specified entity type and base parameter.
    # Delegates to appropriate ViewableEntities concern methods to generate
    # form field configurations with collections, selected values, and metadata.
    #
    # @param entity_type [String] The validated entity type to build options for
    # @param base [String] The sanitized base parameter for form field naming
    #
    # @return [Hash] Entity options hash containing:
    #   - :collection - The available items for selection
    #   - :selected - Currently selected item IDs
    #   - :input_html - HTML attributes for form inputs
    #   - :as - Form field type (:select, :grouped_select, etc.)
    #   - Other metadata specific to the entity type
    #
    # @raise [ArgumentError] If entity_type is not supported (should not happen with validation)
    #
    # @note Relies on ViewableEntities concern methods for actual option building
    # @see ViewableEntities concern for individual entity building methods
    private def build_entity_options(entity_type, base)
      case entity_type
      when 'data_sources'
        data_source_viewability(base)
      when 'organizations'
        organization_viewability(base)
      when 'projects'
        project_viewability(base)
      when 'project_access_groups'
        project_access_group_viewability(base)
      when 'coc_codes'
        coc_viewability(base)
      when 'reports'
        user_reports_assignability(base)
      when 'project_groups'
        project_groups_editability(base)
      when 'cohorts'
        cohort_editability(base)
      else
        raise ArgumentError, "Unsupported entity type: #{entity_type}"
      end
    end

    private def copy_user_groups
      return unless @user
      return unless user_params[:copy_form_id].present?

      source_user = User.active.not_system.find(user_params[:copy_form_id].to_i)
      return unless source_user

      source_user.user_groups.each do |group|
        group.add(@user)
      end
    end

    def destroy
      @user.paper_trail_event = 'deactivate'
      # update_column() allows us to update the user even if the record is invalid
      @user.update_column(:active, false)
      redirect_to({ action: :index }, notice: "User #{@user.name} deactivated")
    end

    def title_for_show
      @user.name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show

    def title_for_index
      'User List'
    end

    private def changing_to_acls?
      params[:user][:permission_context] == 'acls' && @user.permission_context != params[:user][:permission_context]
    end

    private def changing_to_role_based?
      params[:user][:permission_context] == 'role_based' && @user.permission_context != params[:user][:permission_context]
    end

    private def user_using_or_changing_to_acls?
      @user.using_acls? || changing_to_acls?
    end

    private def assigned_user_group_ids
      user_params[:user_group_ids]&.reject(&:blank?)&.map(&:to_i) || []
    end

    private def user_scope
      User.active.not_system
    end

    private def user_params
      base_params = params[:user] || ActionController::Parameters.new
      base_params.permit(
        :connector_id,
        :last_name,
        :first_name,
        :email,
        :talent_lms_email,
        :phone,
        :credentials,
        :agency_id,
        :exclude_from_directory,
        :exclude_phone_from_directory,
        :notify_on_new_account,
        :receive_file_upload_notifications,
        :notify_on_vispdat_completed,
        :notify_on_client_added,
        :notify_on_anomaly_identified,
        :receive_account_request_notifications,
        :training_completed,
        :copy_form_id,
        :permission_context,
        user_group_ids: [],
        superset_roles: [],
        # TODO: START_ACL remove when ACL transition complete
        legacy_role_ids: [],
        access_group_ids: [],
        coc_codes: [],
        # END_ACL
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
        system_contact_attributes: [:id, alert_definition_ids: []],
      ).

        tap do |result|
          # TODO: START_ACL remove when ACL transition complete
          result[:coc_codes] ||= []
          # re-add system groups so we don't remove them here
          result[:access_group_ids] ||= []
          result[:access_group_ids] += @user.access_groups.system.pluck(:id).map(&:to_s)
          # END_ACL

          # User params will never include system user groups in user_group_ids, re-add any of those before saving
          result[:user_group_ids] ||= []
          result[:user_group_ids] += @user.user_groups.system.pluck(:id)
        end
    end

    private def viewable_params
      params.require(:user).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
        project_groups: [],
      )
    end

    private def manually_sorted?
      params[:sort].present?
    end

    private def sort_column
      params[:sort].presence_in(['email', 'first_name', 'last_name']) || 'last_name'
    end

    private def sort_direction
      params[:direction].presence_in(['asc', 'desc']) || 'asc'
    end

    private def set_user
      @user = User.find(params[:id].to_i)

      @agencies = Agency.order(:name)
    end

    private def set_system_alerts
      @system_alerts = GrdaWarehouse::AlertDefinition.system_alerts.active.order(:name)
    end

    private def ensure_system_contact
      @user.build_system_contact if @user.system_contact.nil?
    end

    private def set_available_idps
      # Build list of available IDPs that have service configs and support user management
      @available_idps = []

      # Check Idp::ServiceConfig records
      Idp::ServiceConfig.active.each do |config|
        service = config.to_service
        @available_idps << [config.connector_id, service.idp_name] if service.supports_user_management?
      end
    end

    private def perform_search(search_params = {})
      @query = search_params['q'].presence
      if @query
        @users = user_scope.text_search(@query, sort_by_best_match: !manually_sorted?)
      else
        @users = user_scope.none
      end

      @users = @users.order(sort_column => sort_direction) if manually_sorted?
      @pagy, @users = pagy(@users)
      render :index
    end

    private def handle_invalid_query(message)
      flash[:error] = message
      redirect_to admin_users_path
    end
  end
end
