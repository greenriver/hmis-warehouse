###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserConcern
  extend ActiveSupport::Concern
  included do
    include Rails.application.routes.url_helpers
    include UserPermissions
    include PasswordRules
    include ArelHelper
    has_paper_trail ignore: [:provider_raw_info]
    acts_as_paranoid

    attr_accessor :remember_device, :device_name, :client_access_arbiter, :copy_form_id

    # Include default devise modules. Others available are:
    devise :invitable,
           :recoverable,
           :rememberable,
           :trackable,
           # :validatable,
           :secure_validatable,
           :lockable,
           :timeoutable,
           :confirmable,
           :session_limitable,
           :pwned_password,
           :expirable,
           :password_expirable,
           :password_archivable,
           :two_factor_authenticatable,
           :two_factor_backupable,
           password_length: 10..128,
           otp_secret_encryption_key: ENV['ENCRYPTION_KEY'],
           otp_number_of_backup_codes: 10

    include OmniauthSupport

    # Doorkeeper
    has_many :access_grants, class_name: 'Doorkeeper::AccessGrant', foreign_key: :resource_owner_id, dependent: :delete_all # or :destroy if you need callbacks
    has_many :access_tokens, class_name: 'Doorkeeper::AccessToken', foreign_key: :resource_owner_id, dependent: :delete_all # or :destroy if you need callbacks

    # Connect users to login attempts
    has_many :login_activities, as: :user

    # TODO: START_ACL remove when ACL transition complete
    # Ensure that users have a user-specific access group
    after_save :create_access_group
    # END_ACL

    validates :email, presence: true, uniqueness: true, email_format: { check_mx: true }, length: { maximum: 250 }, on: :update
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
      where(receive_file_upload_notifications: true)
    end

    scope :receives_account_request_notifications, -> do
      where(receive_account_request_notifications: true)
    end

    scope :receives_new_account_notifications, -> do
      where(notify_on_new_account: true)
    end

    scope :active, -> do
      where(
        arel_table[:active].eq(true).and(
          arel_table[:expired_at].eq(nil).
          or(arel_table[:expired_at].gt(Time.current)),
        ).and(
          arel_table[:last_activity_at].eq(nil).
          or(arel_table[:last_activity_at].gt(expire_after.ago)),
        ),
      )
    end

    scope :inactive, -> do
      where(
        arel_table[:active].eq(false).
        or(arel_table[:expired_at].lteq(Time.current)).
        or(arel_table[:last_activity_at].lteq(expire_after.ago)),
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

    scope :has_recent_activity, -> do
      where(last_activity_at: timeout_in.ago..Time.current).
        where.not(unique_session_id: nil)
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
      where(permission_context: 'acls').exists?
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

    def active_for_authentication?
      super && active
    end

    # Allow logins to be case insensitive at login time
    def self.find_for_authentication(conditions)
      conditions[:email].downcase!
      super(conditions)
    end

    def timeout_time(session)
      Time.current + (Devise.timeout_in - (Time.now.utc - (session['last_request_at'].presence || 0)).to_i)
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

    def stale_account?
      current_sign_in_at < self.class.stale_account_threshold
    end

    def impersonateable_by?(user)
      return false unless user.present?

      user != self
    end

    def training_status
      return 'Not Started' unless Talentlms::Login.find_by(user: self)

      if last_training_completed
        "Completed #{last_training_completed}"
      else
        'In Progress'
      end
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

    def two_factor_label
      Translation.translate('Boston DND HMIS Warehouse')
    end

    def two_factor_issuer
      "#{two_factor_label} #{email}"
    end

    def my_root_path
      return clients_path if GrdaWarehouse::Config.client_search_available? && can_search_own_clients?
      return warehouse_reports_path if can_view_any_reports?
      return censuses_path if can_view_censuses?

      root_path
    end

    # ensure we have a secret
    def set_initial_two_factor_secret!
      return if otp_secret.present?

      update(otp_secret: User.generate_otp_secret)
    end

    def two_factor_enabled?
      otp_secret.present? && otp_required_for_login? && passed_2fa_confirmation?
    end

    def confirmation_step
      (confirmed_2fa + 1).ordinalize
    end

    def passed_2fa_confirmation?
      confirmed_2fa.positive?
    end

    def disable_2fa!
      update(
        confirmed_2fa: 0,
        otp_required_for_login: false,
        otp_backup_codes: nil,
      )
    end

    def record_failure_and_lock_access_if_exceeded!
      # Due to a bug, failed PWs double increment failed attempts. To
      # compensate, we double the lockout threshold. To match the PW
      # behavior, double up on failures due to OTP
      # https://github.com/tinfoil/devise-two-factor/issues/28
      transaction do
        2.times do # intentional double increment
          increment_failed_attempts
        end
      end
      # outside of transaction since this method sends email
      return unless attempts_exceeded?

      lock_access! unless access_locked?
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

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"
      where(
        arel_table[:last_name].matches(query).
        or(arel_table[:first_name].matches(query)).
        or(arel_table[:email].matches(query)),
      )
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
    def data_sources
      viewable GrdaWarehouse::DataSource
    end

    def organizations
      viewable GrdaWarehouse::Hud::Organization
    end

    def projects
      viewable GrdaWarehouse::Hud::Project
    end

    def project_access_groups
      viewable GrdaWarehouse::ProjectAccessGroup
    end

    def reports
      viewable GrdaWarehouse::WarehouseReports::ReportDefinition
    end

    def cohorts
      viewable GrdaWarehouse::Cohort
    end

    def project_groups
      viewable GrdaWarehouse::ProjectGroup
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

      User.where(id: team_member_ids)
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
      group = AccessGroup.for_user(self).first_or_create
      group.access_group_members.where(user_id: id).first_or_create
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
      Rails.cache.delete(key) if force_calculation
      Rails.cache.fetch(key, expires_in: 1.minutes) do
        # TODO: START_ACL cleanup after ACL migration is complete
        if using_acls?
          collections.flat_map(&:coc_codes).reject(&:blank?).uniq
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

    def self.describe_changes(_version, changes)
      changes.slice(*whitelist_for_changes_display).map do |name, values|
        "Changed #{humanize_attribute_name(name)}: from \"#{values.first}\" to \"#{values.last}\"."
      end
    end

    def self.humanize_attribute_name(name)
      name.humanize.titleize
    end

    def self.whitelist_for_changes_display
      [
        'first_name',
        'last_name',
        'email',
        'phone',
        'agency',
        'receive_file_upload_notifications',
        'notify_of_vispdat_completed',
        'notify_on_anomaly_identified',
        'receive_account_request_notifications',
      ].freeze
    end

    private def viewable(model)
      model.where(
        id: GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: access_groups.pluck(:id),
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
