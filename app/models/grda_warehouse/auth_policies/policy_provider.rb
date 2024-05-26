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
    if user.using_acls?
      client_id = id_from_arg(client_or_id, GrdaWarehouse::Hud::Client)
      for_client_using_acls(client_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      legacy_user_role_policy
      # END_ACL
    end
  end

  def for_patient(patient)
    for_client(patient.client_id)
  end

  def for_project(project_or_id)
    if user.using_acls?
      project_id = id_from_arg(project_or_id, GrdaWarehouse::Hud::Project)
      for_project_using_acls(project_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      legacy_user_role_policy
      # END_ACL
    end
  end

  protected

  memoize def for_project_using_acls(project_id)
    collection_ids = GrdaWarehouse::ProjectCollectionMember.where(project_id: project_id).pluck(:collection_id)
    collection_ids += [global_system_data_source_collection_id]
    GrdaWarehouse::AuthPolicies::CollectionPolicy.new(user: user, collection_ids: collection_ids)
  end

  memoize def for_client_using_acls(client_id)
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table

    # collections based on the client's enrollment
    collection_ids = GrdaWarehouse::ProjectCollectionMember.
      joins(project: :clients).
      where(c_t[:id].eq(client_id)).
      pluck(:collection_id)

    # collections based on the client's authoritative data source
    collection_ids += GrdaWarehouse::DataSource.authoritative.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:collection_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:collection_id])

    collection_ids += [global_system_data_source_collection_id]
    GrdaWarehouse::AuthPolicies::CollectionPolicy.new(user: user, collection_ids: collection_ids)
  end

  memoize def global_system_data_source_collection_id
    Collection.system_collection(:data_sources).id
  end

  def handle_legacy_unauthorized
    message = "legacy authorization not performed for User##{user.id}"
    raise message unless Rails.env.production?

    # per discussion with Elliot, we log the message in production but continue anyways. It's possible partials that use
    # policies for legacy users are included into controllers that do not set legacy_implicitly_assume_authorized_access
    Sentry.capture_message(message)
  end

  # TODO: START_ACL remove after ACL migration is complete
  memoize def legacy_user_role_policy
    handle_legacy_unauthorized unless legacy_implicitly_assume_authorized_access
    GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy.new(user: user)
  end
  # END_ACL

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
end
