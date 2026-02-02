###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern shared across query resolves (BaseObject) and mutations (BaseMutation/CleanBaseMutation)
module GraphqlApplicationHelper
  extend ActiveSupport::Concern

  def current_user
    context[:current_user]
  end

  def true_user
    context[:true_user]
  end

  def hud_user
    Hmis::Hud::User.from_user(current_user)
  end

  def access_denied!(message = 'access denied')
    raise message
  end

  def policy_for(resource, policy_type:)
    current_user.policy_for(resource, policy_type: policy_type)
  end

  # Does the current user have the given permission on entity?
  #
  # @param permission [Symbol] :can_do_foo
  # @param entity [#record] Client, project, etc
  def current_permission?(permission:, entity:)
    GraphqlPermissionChecker.current_permission_for_context?(context, permission: permission, entity: entity)
  end

  def data_source_client_preloader
    # memoize into context; data source relies on stable object identity
    context[:data_source_client_preloader] ||= ->(clients) {
      client_ids = clients.compact.map(&:id)
      current_user.policy_context.preload_client_dependencies(client_ids)
    }
  end

  # Helper that should be used in place of `load_ar_association(object, :client)`.
  # Preloads client authorization dependencies to avoid n+1s
  def load_ar_client_association(object, association_name: :client)
    load_ar_association(object, association_name, onload: data_source_client_preloader)
  end

  # Helper that should be used in place of `load_ar_scope(scope: Hmis::Hud::Client.all, id: x)` (or similar).
  # Preloads client authorization dependencies to avoid n+1s
  def load_ar_client_scope(scope:, id:)
    load_ar_scope(scope: scope, id: id, onload: data_source_client_preloader)
  end

  # Use data loader to load an ActiveRecord association.
  def load_ar_association(object, association_name, onload: nil)
    raise "object must be a GrdaWarehouseBase, got #{object.class.name}" unless object.is_a?(ActiveRecord::Base)

    # if we already have preloaded association, just return it
    return object.public_send(association_name) if object.association(association_name).loaded? && onload.blank?

    dataloader.with(Sources::ActiveRecordAssociation, association_name, onload: onload).load(object)
  end

  def load_ar_scope(scope:, id:, onload: nil)
    dataloader.with(Sources::ActiveRecordScope, scope, onload: onload).load(id)
  end

  # Helper to resolve the active enrollment for this client at the specified project on the specified date.
  # Include WIP enrollments. If there are multiple enrollments, choose the one with the older entry date.
  # This is in this module because its shared between query and mutation code.
  def load_open_enrollment_for_client(client, project_id:, open_on_date:)
    # Load all enrollments for the client
    enrollments = load_ar_association(client, :enrollments_with_exits)

    # Filter to only enrollments the user has permission to see;
    # Filter down to open enrollments in the specified project on the specified date
    enrollments.filter do |en|
      has_permission = current_permission?(permission: :can_view_enrollment_details, entity: en)
      has_permission && en.open_on_date?(open_on_date) && en.project_pk.to_s == project_id.to_s
    end.min_by { |e| [e.entry_date, e.id] }
  end

  # Resolves the name of a destination client conservatively.
  # It checks if the current user has permission to view the client name
  # on any of the destination client's HMIS source clients (for the current HMIS data source).
  # If no viewable name is found, it returns nil.
  def load_destination_client_name(destination_client:)
    source_clients = load_ar_association(destination_client, :hmis_source_clients)

    source_clients.sort_by(&:id).find do |client|
      current_permission?(permission: :can_view_clients, entity: client) && current_permission?(permission: :can_view_client_name, entity: client)
    end&.brief_name
  end

  def arel
    Hmis::ArelHelper.instance
  end
end
