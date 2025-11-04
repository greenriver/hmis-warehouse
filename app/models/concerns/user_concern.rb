###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

module UserConcern
  extend ActiveSupport::Concern
  include HasPiiAttributes

  included do
    include Rails.application.routes.url_helpers
    include UserPermissions
    include PasswordRules
    include ArelHelper
    has_paper_trail ignore: [:provider_raw_info]
    acts_as_paranoid

    pii_attr :first_name
    pii_attr :last_name
    pii_attr :email
    pii_attr :unconfirmed_email, as: :email
    pii_attr :phone

    attr_accessor :remember_device, :device_name, :client_access_arbiter, :copy_form_id

    # Encrypted OTP secret (read-only, legacy 2FA data)
    # 2FA is now handled by IDP, but we keep this for backward compatibility
    # Configure attr_encrypted to match devise-two-factor's encryption setup
    # Note: Legacy encrypted data may not be decryptable with current configuration
    attr_encrypted :otp_secret,
                   key: proc { |_instance| ENV['ENCRYPTION_KEY']&.[](0..31) },
                   attribute: :encrypted_otp_secret,
                   iv: :encrypted_otp_secret_iv,
                   salt: :encrypted_otp_secret_salt,
                   encode: true,
                   encode_iv: true,
                   encode_salt: true,
                   mode: :per_attribute_iv_and_salt

    # Doorkeeper
    has_many :access_grants, class_name: 'Doorkeeper::AccessGrant', foreign_key: :resource_owner_id, dependent: :delete_all # or :destroy if you need callbacks
    has_many :access_tokens, class_name: 'Doorkeeper::AccessToken', foreign_key: :resource_owner_id, dependent: :delete_all # or :destroy if you need callbacks

    # Connect users to login attempts.
    # Only includes Warehouse activity when called on User record, and only HMIS activity for Hmis::User record.
    has_many :login_activities, as: :user

    # All login activities for user, including both HMIS and Warehouse login activity
    has_many :all_login_activities, class_name: 'LoginActivity', foreign_key: 'user_id'

    # TODO: START_ACL remove when ACL transition complete
    # Ensure that users have a user-specific access group
    after_save :create_access_group
    # END_ACL

    # No longer validating MX record, just validate email format (MX check requires a network connection)
    validates :email, presence: true, uniqueness: true, email_format: { check_mx: false }, length: { maximum: 250 }
    validate :password_cannot_be_sequential, on: :update
    validates :last_name, presence: true, length: { maximum: 40 }
    validates :first_name, presence: true, length: { maximum: 40 }
    validates :email_schedule, inclusion: { in: Message::SCHEDULES }, allow_blank: false
    validates :agency_id, presence: true

    has_many :user_clients, class_name: 'GrdaWarehouse::UserClient'
    has_many :clients, through: :user_clients, inverse_of: :users, dependent: :destroy

    has_many :messages
    has_many :document_exports, dependent: :destroy, class_name: 'GrdaWarehouse::DocumentExport'
    has_many :health_document_exports, dependent: :destroy, class_name: 'Health::DocumentExport'
    has_many :activity_logs

    has_many :two_factors_memorized_devices
    has_many :oauth_identities, dependent: :destroy

    has_many :favorites
    has_many :favorite_reports, through: :favorites, source: :entity, source_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition'

    belongs_to :agency, optional: true

    scope :diet, -> do
      cols = (column_names - ['provider_raw_info', 'coc_codes', 'otp_backup_codes', 'deprecated_provider', 'deprecated_provider_raw_info', 'deprecated_uid', 'deprecated_agency', 'deprecated_provider_set_at']).map { |c| arel_table[c].to_sql }
      select(*cols)
    end

    scope :receives_file_notifications, -> do
      subscribed_to_alert('file_upload')
    end

    scope :receives_account_request_notifications, -> do
      subscribed_to_alert('account_request')
    end

    scope :receives_new_account_notifications, -> do
      subscribed_to_alert('new_account')
    end

    scope :notifies_on_vispdat_completed, -> do
      subscribed_to_alert('vispdat_completed')
    end

    scope :notifies_on_client_added, -> do
      subscribed_to_alert('client_added')
    end

    scope :notifies_on_anomaly_identified, -> do
      subscribed_to_alert('anomaly_identified')
    end

    # Generic scope for finding users subscribed to a specific alert by code
    # Note: Cannot join across databases, so we query contact_alert_subscriptions first
    scope :subscribed_to_alert, ->(alert_code) do
      definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
      return none unless definition

      # Get user IDs from warehouse database
      subscribed_user_ids = GrdaWarehouse::Contact::User.
        joins(:contact_alert_subscriptions).
        merge(GrdaWarehouse::ContactAlertSubscription.where(alert_definition_id: definition.id, active: true)).
        pluck(:entity_id)

      where(id: subscribed_user_ids)
    end

    # Get account expiration period in days.
    #
    # Returns the number of days after which an account is considered expired due to inactivity.
    # Defaults to 180 days if not configured.
    #
    # @return [Integer] Number of days
    def self.expire_after
      (ENV['ACCOUNT_EXPIRATION_DAYS']&.presence || 180).to_i
    end

    scope :active, -> do
      where(
        arel_table[:active].eq(true).and(
          arel_table[:expired_at].eq(nil).
          or(arel_table[:expired_at].gt(Time.current)),
        ).and(
          arel_table[:last_activity_at].eq(nil).
          or(arel_table[:last_activity_at].gt(expire_after.days.ago)),
        ),
      )
    end

    scope :inactive, -> do
      where(
        arel_table[:active].eq(false).
        or(arel_table[:expired_at].lteq(Time.current)).
        or(arel_table[:last_activity_at].lteq(expire_after.days.ago)),
      )
    end

    scope :care_coordinators, -> do
      care_coordinator_ids = Health::Patient.pluck(:care_coordinator_id)
      where(id: care_coordinator_ids)
    end

    scope :nurse_care_managers, -> do
      joins(:health_roles).merge(Role.nurse_care_manager)
    end

    scope :not_system, -> { where.not(first_name: 'System') }

    scope :in_directory, -> do
      active.not_system.where(exclude_from_directory: false)
    end

    # users that have currently active sessions (either in the warehouse or in HMIS)
    # Note: Session timeout is now handled by OAuth2-proxy, so we use a default timeout period
    scope :has_recent_activity, -> do
      timeout_period = 30.minutes # Default session timeout period
      where(last_activity_at: timeout_period.ago..Time.current).
        where.not(unique_session_id: nil, hmis_unique_session_id: nil)
    end

    scope :using_acls, -> do
      where(permission_context: 'acls')
    end

    scope :using_role_based, -> do
      where(permission_context: [nil, 'role_based'])
    end

    def using_acls?
      # Note using hash syntax to get around lack of column for some data migrations
      self[:permission_context].to_s == 'acls'
    end

    def self.available_permission_contexts
      {
        acls: 'Access Controls (modern granular access)',
        role_based: 'Role-Based Access',
      }
    end

    def self.anyone_using_acls?
      Rails.cache.fetch('user/anyone_using_acls', expires_in: 1.minutes) do
        active.not_system.using_acls.exists?
      end
    end

    def self.all_using_acls?
      Rails.cache.fetch('user/all_using_acls', expires_in: 1.minutes) do
        ! active.not_system.using_role_based.exists?
      end
    end

    # scope :admin, -> { includes(:roles).where(roles: {name: :admin}) }
    # scope :dnd_staff, -> { includes(:roles).where(roles: {name: :dnd_staff}) }

    def can_access_project?(project, permission: :can_view_projects)
      return false unless send("#{permission}?")

      cached_viewable_project_ids(permission: permission).include?(project.id)
    end

    def can_view_censuses?
      GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(self).where(url: 'censuses').exists?
    end

    # Check if account is locked (application-level lock, independent of IDP).
    #
    # Even if a user can authenticate via IDP, they may be locked at the application level.
    # This prevents access to the application until an administrator unlocks the account.
    #
    # @return [Boolean] true if account is locked
    def access_locked?
      locked_at.present?
    end

    # Lock access to the application.
    #
    # Sets the locked_at timestamp, preventing access even if IDP authentication succeeds.
    # Administrators can unlock via unlock_access!
    #
    # @return [Boolean] true if lock was successful
    def lock_access!
      update_column(:locked_at, Time.current)
    end

    # Unlock access to the application.
    #
    # Removes the locked_at timestamp, allowing access if other conditions are met.
    #
    # @return [Boolean] true if unlock was successful
    def unlock_access!
      update_column(:locked_at, nil)
    end

    # Check if user account is active and eligible for authentication.
    #
    # Accounts must be:
    # - Active (active = true)
    # - Not expired (expired_at is nil or in the future)
    # - Not locked (locked_at is nil)
    #
    # Note: stale_account? is not checked here as it's only used for reporting purposes.
    # Users can still log in even if their account is stale; only expired accounts are prevented.
    #
    # @return [Boolean] true if account is active and eligible for authentication
    def active_for_authentication?
      active? && !expired_at? && !access_locked?
    end

    # Stub method - authentication is handled by JWT
    def self.find_for_authentication(conditions)
      # Authentication is handled by JWT, not by this method
      # This is kept for backward compatibility
      find_by(email: conditions[:email]&.downcase)
    end

    # Get session timeout time from JWT token.
    #
    # Attempts to get the expiration time from the JWT token.
    # Falls back to a default timeout if JWT expiration is not available.
    #
    # @param session [Hash] Session hash (unused, kept for compatibility)
    # @return [Time] Expected timeout time
    def timeout_time(_session)
      # Try to get expiration time from JWT token
      jwt_helper = if respond_to?(:request) && request.present?
        access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
        JwtHelper.new(access_token: access_token) if access_token.present?
      end

      jwt_helper&.expiration_time
    end

    def future_expiration?
      expired_at.present? && expired_at > Time.current
    end

    def limited_client_view?
      ! can_view_clients?
    end

    def self.stale_account_threshold
      30.days.ago
    end

    # Check if account is stale (unused for extended period).
    #
    # Accounts that haven't been active recently are considered stale.
    # This is used for reporting purposes only - stale accounts can still log in.
    # Only accounts that have passed their expiration date are prevented from logging in.
    #
    # @return [Boolean] true if account is stale
    def stale_account?
      return false if last_activity_at.blank?

      last_activity_at < self.class.stale_account_threshold
    end

    def impersonateable_by?(user)
      return false unless user.present?

      user != self
    end

    def training_status(course)
      login = Talentlms::Login.find_by(user: self, config: course.config)
      return 'Not Started' unless login

      completion_date = Talentlms::CompletedTraining.find_by(course: course, login: login)&.completion_date

      if completion_date
        "Completed #{completion_date}"
      else
        'In Progress'
      end
    end

    def training_renewal_date(course)
      return 'Never' unless course.months_to_expiration.present?

      login = Talentlms::Login.find_by(user: self, config: course.config)
      return nil unless login

      completion_date = Talentlms::CompletedTraining.find_by(course: course, login: login)&.completion_date
      return nil unless completion_date

      if Talentlms::Facade.expiration_duration_period == :days
        completion_date + course.months_to_expiration.days
      else
        completion_date + course.months_to_expiration.months
      end
    end

    def required_training_courses(date = Date.current)
      return Talentlms::Course.active_on_date(date).where(id: training_courses&.compact_blank) if training_courses&.compact_blank&.present?
      return Talentlms::Course.active_on_date(date).default if training_required?

      []
    end

    # def role_keys
    #   [:admin, :dnd_staff, :housing_subsidy_admin]
    #     .select { |role| attributes[role.to_s] }
    # end

    # def roles_string
    #   role_keys
    #     .map { |role_key| role_key.to_s.humanize.gsub 'Dnd', 'DND' }
    #     .join(', ')
    # end

    def name
      "#{first_name} #{last_name}"
    end

    def name_with_email
      "#{name} <#{email}>"
    end

    def name_with_credentials
      return "#{name}, #{credentials}" if credentials.present?

      name
    end

    def agency_name
      agency&.name if agency.present?
    end

    def phone_for_directory
      phone unless exclude_phone_from_directory
    end

    def show_credentials?
      # Show the credentials field if the user has at least one health role
      roles.health.exists?
    end

    def credential_options
      @credential_options ||= User.pluck(:credentials).compact.uniq.sort
    end

    def my_root_path
      return clients_path if GrdaWarehouse::Config.client_search_available? && can_search_own_clients?
      return warehouse_reports_path if can_view_any_reports?
      return censuses_path if can_view_censuses?

      root_path
    end

    def invitation_status
      if invitation_accepted_at.present? || invitation_sent_at.blank?
        :active
      elsif invitation_due_at > Time.now
        :pending_confirmation
      else
        :invitation_expired
      end
    end

    # Force user logout by invalidating their session.
    #
    # Updates the custom_session_invalidator, which forces re-authentication on next request.
    # This is used when administrators need to force a user to re-authenticate.
    #
    # @return [Boolean] true if logout was forced
    def force_logout!
      update_attribute(:custom_session_invalidator, SecureRandom.hex)
    end

    # Check if user has pending confirmation.
    #
    # Email confirmation is handled by IDP, but invitations may still be pending.
    #
    # @return [Boolean] true if invitation is pending
    def pending_any_confirmation
      invitation_token.present?
    end

    # @return [Array] an array of text that describes the status of the account
    def overall_status(current_user)
      return ['Active'] if active_for_authentication?
      return ['Pending invitation confirmation'] if invitation_status == :pending_confirmation

      text = []
      text << 'Invitation expired' if invitation_status == :invitation_expired
      if expired_at?
        text << "Account expired on #{expired_at}"
      elsif expired?
        text << "Account expired due to inactivity. Last activity on #{last_activity_at}"
      else
        text << deactivation_status(current_user)
      end
      text
    end

    def deactivation_status(user)
      return unless inactive?

      # The PaperTrail versions association has a fixed order with newest last
      version = versions.where(event: 'deactivate').last

      return 'Account deactivated' unless version
      return "Account deactivated on #{version.created_at}" unless user.can_audit_users? || version.whodunnit.blank?

      name = nil
      name = User.find_by(id: version.whodunnit)&.name if version.whodunnit&.to_i&.to_s == version.whodunnit

      return "Account deactivated on #{version.created_at}" unless name

      "Account deactivated by #{name} on #{version.created_at}"
    end

    # Search for users by name or email using prefix matching
    #
    # @param text [String] the search query
    # @param sort_by_best_match [Boolean] whether to order results by similarity to query
    #
    # @return [ActiveRecord::Relation] matching users
    #
    # @example Find users matching 'john'
    #   User.text_search('john')
    def self.text_search(text, sort_by_best_match: false)
      text = text.strip
      return none if text.length < 3 # require at least 3 characters for meaningful search

      terms = text.split(/[\s,]+/).map(&:strip).reject(&:blank?)
      return none if terms.empty?

      scope = terms.map do |term|
        prefix_condition = arel_table[:first_name].matches("#{term}%").
          or(arel_table[:last_name].matches("#{term}%")).
          or(arel_table[:email].matches("#{term}%"))

        where(prefix_condition)
      end.inject(&:or)
      if sort_by_best_match
        sql = <<-SQL.squish
          similarity(
            CONCAT_WS(' ', first_name, last_name, email),
            ?
          ) DESC
        SQL
        scope.order(Arel.sql(sanitize_sql_array([sql, text])))
      else
        scope
      end
    end

    def self.setup_system_user
      user = find_by(email: 'noreply@greenriver.com')
      return user if user.present?

      user = only_deleted.find_by(email: 'noreply@greenriver.com')
      user&.restore
      return user if user.present?

      invite!(email: 'noreply@greenriver.com', first_name: 'System', last_name: 'User', agency_id: 0) do |u|
        u.skip_invitation = true
      end
    end

    # Invite a user (class method).
    #
    # Creates a new user account and optionally sends an invitation.
    # If IDP supports invitations and connector_id is set, sends invitation via IDP.
    # Otherwise, creates a shell user that will be linked on first login.
    #
    # @param attributes [Hash] User attributes (email, first_name, last_name, etc.)
    # @param invited_by [User, nil] User who is sending the invitation (optional, can be second positional arg)
    # @param skip_invitation [Boolean] Skip sending invitation (default: false)
    # @yield [User] Block to modify user before saving
    # @return [User] Created user instance
    def self.invite!(attributes = {}, invited_by = nil, skip_invitation: false)
      # Handle legacy signature: invite!(attributes, invited_by_user)
      if invited_by.is_a?(User)
        # Second positional argument is the invited_by user
      elsif attributes.is_a?(User) && invited_by.nil?
        # Legacy signature: invite!(user, nil) - attributes is actually the invited_by user
        invited_by = attributes
        attributes = {}
      end

      attributes = attributes.dup.with_indifferent_access
      email = attributes[:email] || attributes['email']
      connector_id = attributes.delete(:connector_id) || attributes.delete('connector_id')

      # Check if user already exists
      user = find_by(email: email)
      if user
        # User exists - resend invitation if requested
        user.invite!(invited_by: invited_by, skip_invitation: skip_invitation)
        return user
      end

      # Create new user
      user = new(attributes)
      user.skip_invitation = skip_invitation || attributes[:skip_invitation] == true || attributes['skip_invitation'] == true
      user.invited_by = invited_by if invited_by

      # Allow block to modify user
      yield user if block_given?

      # Generate invitation token and set timestamps
      unless user.skip_invitation
        user.invitation_token = SecureRandom.hex(32)
        user.invitation_created_at = Time.current
        user.invitation_sent_at = Time.current
        user.invitation_due_at = 7.days.from_now if user.respond_to?(:invitation_due_at=)
      end

      # Set confirmed_at based on skip_invitation
      user.confirmed_at = user.skip_invitation ? Time.current : nil
      user.active = true

      # Save user first
      user.save!

      # Send invitation via IDP if supported
      unless user.skip_invitation
        if connector_id && Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
          idp_service = Idp::ServiceFactory.for_connector(connector_id)
          begin
            idp_service.send_invitation(
              email: user.email,
              first_name: user.first_name || '',
              last_name: user.last_name || '',
              phone: user.phone,
            )

            # Create authentication source with placeholder
            user.user_authentication_sources.create!(
              connector_id: connector_id,
              connector_user_id: user.email, # Temporary placeholder
              enabled: true,
            )
          rescue Idp::ServiceError => e
            Rails.logger.error "Failed to send invitation via IDP: #{e.message}"
            user.errors.add(:base, "Failed to send invitation: #{e.message}")
          end
        end
      end

      user
    end

    # Invite an existing user (instance method).
    #
    # Resends invitation for an existing user.
    # If IDP supports invitations and user has a connector_id, sends invitation via IDP.
    #
    # @param invited_by [User, nil] User who is sending the invitation (optional, kept for API compatibility)
    # @param skip_invitation [Boolean] Skip sending invitation (default: false)
    # @return [User] Self
    def invite!(_invited_by: nil, skip_invitation: false)
      return self if skip_invitation

      # Generate new invitation token and update timestamps
      self.invitation_token = SecureRandom.hex(32)
      self.invitation_created_at = Time.current
      self.invitation_sent_at = Time.current
      self.invitation_due_at = 7.days.from_now if respond_to?(:invitation_due_at=)
      self.invitation_accepted_at = nil
      self.confirmed_at = nil

      save!

      # Send invitation via IDP if user has a connector and IDP supports invitations
      connector_id = last_connector_id || user_authentication_sources.enabled.first&.connector_id
      if connector_id && Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
        idp_service = Idp::ServiceFactory.for_connector(connector_id)
        begin
          idp_service.send_invitation(
            email: email,
            first_name: first_name || '',
            last_name: last_name || '',
            phone: phone,
          )
        rescue Idp::ServiceError => e
          Rails.logger.error "Failed to send invitation via IDP: #{e.message}"
          errors.add(:base, "Failed to send invitation: #{e.message}")
        end
      end

      self
    end

    def self.system_user
      # Test environments really don't like caching this
      return setup_system_user if Rails.env.test?

      @system_user ||= setup_system_user
    end

    def system_user?
      email == 'noreply@greenriver.com'
    end

    def can_report_on_confidential_projects?
      return true if system_user?

      can_report_on_confidential_projects
    end

    def inactive?
      return true unless active?

      expired?
    end

    # TODO: START_ACL remove when ACL transition complete
    def organizations
      viewable GrdaWarehouse::Hud::Organization
    end

    def projects
      viewable GrdaWarehouse::Hud::Project
    end

    def project_access_groups
      viewable GrdaWarehouse::ProjectAccessGroup
    end

    def associated_by(associations:)
      return [] unless associations.present?

      associations.flat_map do |association|
        case association
        when :coc_code
          coc_codes.map do |code|
            [
              code,
              GrdaWarehouse::Hud::Project.project_names_for_coc(code),
            ]
          end
        when :organization
          organizations.preload(:projects).map do |org|
            [
              org.OrganizationName,
              org.projects.map(&:ProjectName),
            ]
          end
        when :data_source
          data_sources.preload(:projects).map do |ds|
            [
              ds.name,
              ds.projects.map(&:ProjectName),
            ]
          end
        when :project_access_group
          project_access_groups.preload(:projects).map do |pag|
            [
              pag.name,
              pag.projects.map(&:ProjectName),
            ]
          end
        else
          []
        end
      end
    end
    # END_ACL

    # Within the context of a client enrollment, what projects can this user see
    # Note this differs from Project.viewable_by because they may not have access to the actual project
    def visible_project_ids_enrollment_context
      # TODO: START_ACL cleanup after ACL migration is complete
      @visible_project_ids_enrollment_context ||= if using_acls?
        GrdaWarehouse::Hud::Project.viewable_by(self, permission: :can_view_clients).pluck(:id)
      else
        GrdaWarehouse::Hud::Project.viewable_by(self).pluck(:id) |
          GrdaWarehouse::DataSource.visible_in_window_for_cohorts_to(self).joins(:projects).pluck(p_t[:id])
      end
      # END_ACL
    end

    def visible_projects_by_id
      @visible_projects_by_id ||= GrdaWarehouse::Hud::Project.find(visible_project_ids_enrollment_context).index_by(&:id)
    end

    # inverse of GrdaWarehouse::Hud::Project.viewable_by(user)
    def viewable_project_ids
      @viewable_project_ids ||= GrdaWarehouse::Hud::Project.viewable_by(self, permission: :can_view_projects).pluck(:id)
    end

    private def cached_viewable_project_ids(permission: :can_view_projects, force_calculation: false)
      key = [self.class.name, __method__, permission, id]
      Rails.cache.delete(key) if force_calculation
      Rails.cache.fetch(key, expires_in: 1.minutes) do
        GrdaWarehouse::Hud::Project.viewable_by(self, confidential_scope_limiter: :all, permission: permission).pluck(:id).to_set
      end
    end

    def team_mates
      # find all of the team leads for any team this user is a member of
      team_leader_ids = Health::UserCareCoordinator.
        joins(:coordination_team).
        where(user_id: id).
        pluck(:team_coordinator_id)

      # find all of the users on any team I lead, or which I'm a member of
      team_member_ids = Health::UserCareCoordinator.
        joins(:coordination_team).
        merge(Health::CoordinationTeam.lead_by(team_leader_ids + [id])).
        pluck(:user_id)

      User.where(id: team_member_ids).active
    end

    # patients with CC or NCM relationship to this user
    def patients
      Health::Patient.where(care_coordinator_id: id).
        or(Health::Patient.where(nurse_care_manager_id: id))
    end

    # patients with CC relationship to this user
    def care_coordination_patients
      Health::Patient.where(care_coordinator_id: id)
    end

    # TODO: START_ACL remove after ACL migration is complete
    private def create_access_group
      group = access_group
      return group if group.persisted?

      group.name = name
      group.user_id = id
      group.save!
      group.access_group_members.where(user_id: id).first_or_create
      group.reload
      group
    end

    def access_group
      @access_group ||= AccessGroup.for_user(self).first_or_initialize
    end

    def set_viewables(viewables) # rubocop:disable Naming/AccessorMethodName
      return unless persisted?

      access_group.set_viewables(viewables)
    end

    def add_viewable(*viewables)
      viewables.each do |viewable|
        access_group.add_viewable(viewable)
      end
      # invalidate cache of project ids, since we've changed the list
      cached_viewable_project_ids(force_calculation: true)
      coc_codes(force_calculation: true)
    end
    # END_ACL

    def coc_codes(force_calculation: false)
      key = [self.class.name, __method__, id]
      Rails.cache.delete(key) if force_calculation || Rails.env.test?
      Rails.cache.fetch(key, expires_in: 1.minutes) do
        # TODO: START_ACL cleanup after ACL migration is complete
        if using_acls?
          collections.flat_map(&:coc_codes).map(&:coc_code).reject(&:blank?).uniq
        else
          (access_groups.map(&:coc_codes).flatten + access_group.coc_codes).reject(&:blank?).uniq
        end
        # END_ACL
      end
    end

    # TODO: START_ACL remove after ACL migration is complete
    def coc_codes=(codes)
      access_group.update(coc_codes: codes)
    end
    # END_ACL

    def admin_dashboard_landing_path
      return admin_users_path if can_edit_users?
      return admin_configs_path if can_manage_config?
      return admin_translation_keys_path if can_edit_translations?
      return admin_dashboard_imports_path if can_view_imports?
    end

    def subordinates
      return User.none unless can_manage_an_agency?
      return User.none if agency_id.blank?

      users = User.active.order(:first_name, :last_name)
      unless can_manage_all_agencies?
        # The users in the user's agency
        users = users.where(agency_id: agency_id)
      end
      users
    end

    def coc_codes_for_consent
      # return coc_codes if coc_codes.present?
      ConsentLimit.available_coc_codes
    end

    def report_filter_visible?(key)
      return true if can_view_project_related_filters?

      project_related = [
        :project_ids,
        :organization_ids,
        :data_source_ids,
        :funder_ids,
        :funder_others,
        :project_group_ids,
        :projects,
        :organizations,
        :data_sources,
        :funding_sources,
        :project_groups,
      ].freeze

      ! project_related.include?(key.to_sym)
    end

    class << self
      include Memery
      def group_associations
        {
          data_sources: GrdaWarehouse::DataSource,
          organizations: GrdaWarehouse::Hud::Organization,
          projects: GrdaWarehouse::Hud::Project,
          project_access_groups: GrdaWarehouse::ProjectAccessGroup,
          reports: GrdaWarehouse::WarehouseReports::ReportDefinition,
          cohorts: GrdaWarehouse::Cohort,
          project_groups: GrdaWarehouse::ProjectGroup,
        }.freeze
      end
      memoize :group_associations
    end

    # def health_agency
    #   agency_user&.agency
    # end

    # def agency_user
    #   Health::AgencyUser.where(user_id: id).last
    # end

    def health_agencies
      agency_users.map(&:agency).compact
    end

    def health_agency_names
      health_agencies.map(&:name).compact
    end

    def agency_users
      Health::AgencyUser.where(user_id: id)
    end

    # send email upon creation or only in a periodic digest
    def continuous_email_delivery?
      email_schedule.nil? || email_schedule == 'immediate'
    end

    # does this user want to see messages in the app itself (versus only in email)
    # TODO make this depend on some attribute(s) configurable by the user and/or admins
    def in_app_messages?
      true
    end

    def self.describe_changes(...)
      UserEditHistory::UserVersionChangeSummary.new.perform(...)
    end

    def all_access_group_ids
      (access_groups.pluck(:id) + [access_group.id]).compact
    end

    private def viewable(model)
      model.where(
        id: GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: all_access_group_ids,
          entity_type: model.sti_name,
        ).select(:entity_id),
      )
    end

    def skip_session_limitable?
      ENV.fetch('SKIP_SESSION_LIMITABLE', false) == 'true'
    end

    # Returns an array of hashes of access group name => [item names]
    def inherited_for_type(entity_type)
      case entity_type
      when :coc_codes
        access_groups.general.map do |group|
          [
            group.name,
            group.coc_codes,
          ]
        end
      when :projects
        # directly inherited projects
        groups = access_groups.general.map do |group|
          [
            group.name,
            group.public_send(entity_type).map(&:ProjectName).select(&:presence).compact,
          ]
        end
        # indirectly inherited projects from data sources
        access_groups.general.each do |group|
          groups << [
            group.name,
            group.data_sources.flat_map(&:projects).map(&:ProjectName).select(&:presence).compact,
          ]
        end
        # indirectly inherited projects from organizations
        access_groups.general.each do |group|
          groups << [
            group.name,
            group.organizations.flat_map(&:projects).map(&:ProjectName).select(&:presence).compact,
          ]
        end
        # indirectly inherited projects from project_access_groups
        access_groups.general.each do |group|
          groups << [
            group.name,
            group.project_access_groups.flat_map(&:projects).map(&:ProjectName).select(&:presence).compact,
          ]
        end
        # indirectly inherited projects from coc_codes
        access_groups.general.each do |group|
          groups << [
            group.name,
            GrdaWarehouse::Hud::Project.in_coc(coc_code: group.coc_codes).map(&:ProjectName).select(&:presence).compact,
          ]
        end
        groups
      when :organizations
        access_groups.general.map do |group|
          [
            group.name,
            group.public_send(entity_type).map(&:OrganizationName).select(&:presence).compact,
          ]
        end
      else
        access_groups.general.map do |group|
          [
            group.name,
            group.public_send(entity_type).map(&:name).select(&:presence).compact,
          ]
        end
      end
    end
  end
end
