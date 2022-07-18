###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE:
# r = Hmis::Role.create(name: 'test')
# u = Hmis::User.first; u.hmis_data_source_id = 3
# u.user_hmis_data_sources_roles.create(role: r, data_source_id: u.hmis_data_source_id)
# u.can_view_full_ssn?
require 'memoist'
class Hmis::User < ApplicationRecord
  include UserConcern
  self.table_name = :users
  has_many :user_hmis_data_sources_roles, class_name: '::Hmis::UserHmisDataSourceRole', dependent: :destroy, inverse_of: :user # join table with user_id, data_source_id, role_id
  has_many :roles, through: :user_hmis_data_sources_roles, source: :role
  has_many :hmis_data_sources, through: :user_hmis_data_sources_roles, source: :data_source
  attr_accessor :hmis_data_source_id # stores the data_source_id of the currently logged in HMIS

  def skip_session_limitable?
    true
  end

  def can_report_on_confidential_projects
    # TODO: Make this role present on the HMIS user model or Hmis::Hud::Project.viewable_by will error out
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

  def lock_access!(opts = {})
    super opts.merge({ send_instructions: false })
  end
end
