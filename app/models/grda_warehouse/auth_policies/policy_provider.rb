###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

class GrdaWarehouse::AuthPolicies::PolicyProvider
  include Memery
  attr_reader :user

  # TODO: START_ACL remove after ACL migration is complete
  ###
  # The legacy permission policy only checks the permissions on a user's roles and assumes the loaded record is visible
  # to the user already. This is a dangerous assumption so it's required to confirm the record is authorized by
  # setting legacy_implicitly_assume_authorized_access to true.
  # Note this is only relevant for users where using_acls is false
  ###
  attr_accessor :legacy_implicitly_assume_authorized_access
  # END_ACL

  def initialize(user)
    @user = user
  end

  def for_client(client_or_id)
    client_id = id_from_arg(client_or_id, GrdaWarehouse::Hud::Client)
    if user.using_acls?
      client_project_policy(client_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      legacy_user_role_policy
      # END_ACL
    end
  end

  def for_patient(patient)
    for_client(patient.client_id)
  end

  memoize def for_project(project_or_id)
    project_id = id_from_arg(project_or_id, GrdaWarehouse::Hud::Project)
    if user.using_acls?
      GrdaWarehouse::AuthPolicies::ProjectPolicy.new(user: user, project_id: project_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      legacy_user_role_policy
      # END_ACL
    end
  end

  protected

  def handle_legacy_unauthorized
    message = "legacy authorization not performed for User##{user.id}"
    raise message unless Rails.env.production?

    # per discussion with Elliot, we log the message in production but continue anyways. It's possible partials that use
    # policies for legacy users are included into controllers that do not set legacy_implicitly_assume_authorized_access
    Sentry.capture_message(message)
  end

  memoize def client_project_policy(client_id)
    project_policies = visible_client_project_ids(client_id).map do |project_id|
      for_project(project_id)
    end
    GrdaWarehouse::AuthPolicies::AnyPolicy.new(policies: project_policies)
  end

  memoize def window_data_source_ids
    ::GrdaWarehouse::DataSource.window_data_source_ids
  end

  # TODO: START_ACL remove after ACL migration is complete
  memoize def legacy_user_role_policy
    handle_legacy_unauthorized unless legacy_implicitly_assume_authorized_access
    GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy.new(user: user)
  end
  # END_ACL

  # I believe this is correct because it enforces can_view_clients. The access-control system requires this
  # permission for both viewing and searching clients (see note on can_search_own_clients in the role class)
  def visible_client_project_ids(client_id)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    enrollment_arbiter.
      enrollments_visible_to(user, client_ids: [client_id]).
      joins(:project).order(p_t[:id]).pluck(p_t[:id])
  end

  memoize def enrollment_arbiter
    GrdaWarehouse::Config.arbiter_class.new
  end

  def id_from_arg(arg, klass)
    case arg
    when klass
      arg.id
    when Integer, String
      arg.to_i
    else
      raise "invalid argument #{arg.inspect}"
    end
  end

  def deny_policy
    GrdaWarehouse::AuthPolicies::DenyPolicy.instance
  end
end
