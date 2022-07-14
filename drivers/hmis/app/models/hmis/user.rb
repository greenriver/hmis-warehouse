###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: u = Hmis::User.first; u.hmis_data_source_id = 3; u.can_view_full_ssn?
class Hmis::User < ::User
  has_many :user_hmis_data_sources_roles, class_name: '::Hmis::UserHmisDataSourceRole', dependent: :destroy, inverse_of: :user # join table with user_id, data_source_id, role_id
  has_many :roles, through: :user_hmis_data_sources_roles, source: :role
  has_many :hmis_data_sources, through: :user_hmis_data_sources_roles, source: :data_source
  attr_accessor :hmis_data_source_id # stores the data_source_id of the currently logged in HMIS

  def skip_session_limitable?
    true
  end

  # load a hash of permission names (e.g. 'can_view_all_reports')
  # to a boolean true if the user has the permission through one
  # of their roles
  def load_effective_permissions
    {}.tap do |h|
      roles.merge(Hmis::UserHmisDataSourceRole.where(data_source_id: hmis_data_source_id)).each do |role|
        ::Hmis::Role.permissions.each do |permission|
          h[permission] ||= role.send(permission)
        end
      end
    end
  end

  # define helper methods for looking up if this
  # user has an permission through one of its roles
  ::Hmis::Role.permissions.each do |permission|
    define_method(permission) do
      @permissions ||= load_effective_permissions
      @permissions[permission]
    end

    # Methods for determining if a user has permission
    # e.g. the_user.can_administer_health?
    define_method("#{permission}?") do
      send(permission)
    end

    # Provide a scope for each permission to get any user who qualifies
    # e.g. User.can_administer_health
    scope permission, -> do
      joins(:roles).
        where(roles: { permission => true })
    end
  end
end
