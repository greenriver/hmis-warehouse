class User < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  has_paper_trail
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :timeoutable, :confirmable, password_length: 8..128
  #has_secure_password # not needed with devise

  validates :email, presence: true, uniqueness: true, email_format: { check_mx: true }, length: {maximum: 250}, on: :update
  validates :last_name, presence: true, length: {maximum: 40}
  validates :first_name, presence: true, length: {maximum: 40}

  has_many :user_roles, dependent: :destroy, inverse_of: :user
  has_many :roles, through: :user_roles

  # NOTE: users and rows in this join table are in different databases, so transactions
  # aren't going to play well across this boundary
  after_destroy do |user|
    GrdaWarehouse::UserViewableEntity.where( user_id: user.id ).destroy_all
  end

  # scope :admin, -> { includes(:roles).where(roles: {name: :admin}) }
  # scope :dnd_staff, -> { includes(:roles).where(roles: {name: :dnd_staff}) }

  # load a hash of permission names (e.g. 'can_view_reports')
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
      @permisisons ||= load_effective_permissions
      @permisisons[permission]
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

  def data_sources
    viewable GrdaWarehouse::DataSource
  end

  def organizations
    viewable GrdaWarehouse::Hud::Organization
  end

  def projects
    viewable GrdaWarehouse::Hud::Project
  end

  def set_viewables(viewables)
    return unless persisted?
    GrdaWarehouse::UserViewableEntity.transaction do
      %i( data_sources organizations projects ).each do |type|
        ids = ( viewables[type] || [] ).map(&:to_i)
        scope = viewable_join self.send(type)
        scope.where.not( entity_id: ids ).destroy_all
        ( ids - scope.pluck(:id) ).each{ |id| scope.where( entity_id: id ).first_or_create }
      end
    end
  end

  def add_viewable(*viewables)
    viewables.each do |viewable|
      viewable_join(viewable.class).where( entity_id: viewable.id ).first_or_create
    end
  end
  
  def admin_dashboard_landing_path
    return admin_users_path if can_edit_users?
    return admin_translation_keys_path if can_edit_translations?
    return admin_dashboard_imports_path if can_view_imports?
    return admin_health_admin_index_path if can_administer_health?
  end

  private

    def viewable(model)
      if can_edit_anything_super_user?
        model.all
      else
        model.joins(:user_viewable_entities).merge(viewable_join(model))
      end
    end

    def viewable_join(model)
      GrdaWarehouse::UserViewableEntity.where(
        entity_type: model.sti_name, 
        user_id: id
      )
    end

end
