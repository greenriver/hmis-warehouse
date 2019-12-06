###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class User < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include UserPermissions
  has_paper_trail
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :lockable,
         :timeoutable,
         :confirmable,
         :session_limitable,
         :pwned_password,
         :expirable,
         # :password_expirable,
         # :password_archivable,
         :two_factor_authenticatable,
         :two_factor_backupable,
         password_length: 10..128,
         otp_secret_encryption_key: ENV['ENCRYPTION_KEY'],
         otp_number_of_backup_codes: 10
  # has_secure_password # not needed with devise
  # Connect users to login attempts
  has_many :login_activities, as: :user

  # Ensure that users have a user-specific access group
  after_save :create_access_group

  validates :email, presence: true, uniqueness: true, email_format: { check_mx: true }, length: {maximum: 250}, on: :update
  validates :last_name, presence: true, length: {maximum: 40}
  validates :first_name, presence: true, length: {maximum: 40}
  validates :email_schedule, inclusion: { in: Message::SCHEDULES }, allow_blank: false

  has_many :user_roles, dependent: :destroy, inverse_of: :user
  has_many :roles, through: :user_roles

  has_many :access_group_members, dependent: :destroy, inverse_of: :user
  has_many :access_groups, through: :access_group_members

  has_many :user_clients, class_name: 'GrdaWarehouse::UserClient'
  has_many :clients, through: :user_clients, inverse_of: :users, dependent: :destroy

  has_many :messages

  belongs_to :agency

  scope :receives_file_notifications, -> do
    where(receive_file_upload_notifications: true)
  end
  scope :active, -> {where active: true}
  scope :inactive, -> {where active: false}
  scope :not_system, -> { where.not(first_name: 'System') }

  # scope :admin, -> { includes(:roles).where(roles: {name: :admin}) }
  # scope :dnd_staff, -> { includes(:roles).where(roles: {name: :dnd_staff}) }

  # load a hash of permission names (e.g. 'can_view_all_reports')
  # to a boolean true if the user has the permission through one
  # of their roles
  def load_effective_permissions
    {}.tap do |h|
      roles.each do |role|
        Role.permissions.each do |permission|
          h[permission] ||= role.send(permission)
        end
      end
    end
  end

  # define helper methods for looking up if this
  # user has an permission through one of its roles
  Role.permissions.each do |permission|
    define_method(permission) do
      @permissions ||= load_effective_permissions
      @permissions[permission]
    end

    # Methods for determining if a user has permission
    # e.g. the_user.can_administer_health?
    define_method("#{permission}?") do
      self.send(permission)
    end

    # Provide a scope for each permission to get any user who qualifies
    # e.g. User.can_administer_health
    scope permission, -> do
      joins(:roles).
      where(roles: {permission => true})
    end
  end

  def active_for_authentication?
    super && active
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

  def two_factor_issuer
    _('Boston DND HMIS Warehouse')
  end

  def two_factor_label
    "#{two_factor_issuer} #{email}"
  end

  # ensure we have a secret
  def set_initial_two_factor_secret!
    return if otp_secret
    update(otp_secret: User.generate_otp_secret)
  end

  def two_factor_enabled?
    otp_secret.present? && otp_required_for_login? && passed_2fa_confirmation?
  end

  def confirmation_step
    (confirmed_2fa + 1).ordinalize
  end

  def passed_2fa_confirmation?
    confirmed_2fa > 0
  end

  def disable_2fa!
    otp_secret = nil
    update(
      confirmed_2fa: 0,
      otp_required_for_login: false,
      otp_backup_codes: nil,
    )
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

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:last_name].matches(query)
      .or(arel_table[:first_name].matches(query))
      .or(arel_table[:email].matches(query))
    )
  end

  def self.setup_system_user
    user = User.find_by(email: 'noreply@greenriver.com')
    return user if user.present?
    user = User.with_deleted.find_by(email: 'noreply@greenriver.com')
    if user.present?
      user.restore
    end
    user = User.invite!(email: 'noreply@greenriver.com', first_name: 'System', last_name: 'User') do |u|
      u.skip_invitation = true
    end
    return user
  end

  def data_sources
    viewable GrdaWarehouse::DataSource
  end

  def organizations
    viewable GrdaWarehouse::Hud::Organization
  end

  def projects
    viewable GrdaWarehouse::Hud::Project
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

  def associated_by associations:
    return [] unless associations.present?
    associations.flat_map do |association|
      case association
      when :coc_code
        coc_codes.map do |code|
          [
            code,
            GrdaWarehouse::Hud::Project.project_names_for_coc(code)
          ]
        end
      when :organization
        organizations.preload(:projects).map do |org|
          [
            org.OrganizationName,
            org.projects.map(&:ProjectName)
          ]
        end
      when :data_source
        data_sources.preload(:projects).map do |ds|
          [
            ds.name,
            ds.projects.map(&:ProjectName)
          ]
        end
      else
        []
      end
    end
  end

  def user_care_coordinators
    Health::UserCareCoordinator.where(user_id: id)
  end

  def care_coordinators
    ids = user_care_coordinators.pluck(:care_coordinator_id)
    User.where(id: ids)
  end

  def user_team_coordinators
    Health::UserCareCoordinator.where(care_coordinator_id: id)
  end

  def team_coordinators
    ids = user_team_coordinators.pluck(:user_id)
    User.where(id: ids)
  end

  private def create_access_group
    group = AccessGroup.for_user(self).first_or_create
    group.access_group_members.where(user_id: id).first_or_create
  end

  def access_group
    AccessGroup.for_user(self).first_or_initialize
  end

  def set_viewables(viewables)
    return unless persisted?
    access_group.set_viewables(viewables)
  end

  def add_viewable(*viewables)
    viewables.each do |viewable|
      access_group.add_viewable(viewable)
    end
  end

  def coc_codes
    access_group.coc_codes
  end

  def coc_codes= (codes)
    access_group.update(coc_codes: codes)
  end

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
      users = users.where(agency_id: self.agency_id)
    end
    users
  end

  def coc_codes_for_consent
    # return coc_codes if coc_codes.present?
    GrdaWarehouse::Hud::ProjectCoc.available_coc_codes
  end

  # def health_agency
  #   agency_user&.agency
  # end

  # def agency_user
  #   Health::AgencyUser.where(user_id: id).last
  # end

  def health_agencies
    agency_users.map(&:agency)
  end

  def health_agency_names
    health_agencies.map(&:name)
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

  def self.describe_changes(version, changes)
    changes.slice(*whitelist_for_changes_display).map do |name, values|
      "Changed #{humanize_attribute_name(name)}: from \"#{values.first}\" to \"#{values.last}\"."
    end
  end

  def self.humanize_attribute_name(name)
    name.humanize.titleize
  end

  private

    def self.whitelist_for_changes_display
      [
        'first_name',
        'last_name email',
        'phone',
        'agency',
        'receive_file_upload_notifications',
        'notify_of_vispdat_completed',
        'notify_on_anomaly_identified',
      ].freeze
    end

    def viewable(model)
      if can_edit_anything_super_user?
        model.all
      else
        model.where(
          id: GrdaWarehouse::GroupViewableEntity.where(
            access_group_id: access_groups.pluck(:id),
            entity_type: model.sti_name,
          ).select(:entity_id),
        )
      end
    end
end
