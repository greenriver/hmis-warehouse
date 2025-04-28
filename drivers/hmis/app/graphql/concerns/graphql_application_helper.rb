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

  # Does the current user have the given permission on entity?
  #
  # @param permission [Symbol] :can_do_foo
  # @param entity [#record] Client, project, etc
  def current_permission?(permission:, entity:)
    GraphqlPermissionChecker.current_permission_for_context?(context, permission: permission, entity: entity)
  end

  # Use data loader to load an ActiveRecord association.
  def load_ar_association(object, association_name)
    raise "object must be a GrdaWarehouseBase, got #{object.class.name}" unless object.is_a?(ActiveRecord::Base)

    # if we already have preloaded association, just return it
    return object.public_send(association_name) if object.association(association_name).loaded?

    dataloader.with(Sources::ActiveRecordAssociation, association_name).load(object)
  end

  def load_ar_scope(scope:, id:)
    dataloader.with(Sources::ActiveRecordScope, scope).load(id)
  end

  # Helper to resolve the active enrollment for this client at the specified project on the specified date.
  # Include WIP enrollments. If there are multiple enrollments, choose the one with the older entry date.
  #
  # This is in this module because its shared between query and mutation code.
  def load_open_enrollment_for_client(client, project_id:, open_on_date:)
    # Confirm the user has access to view enrollments in the specified project
    project = Hmis::Hud::Project.find_by(id: project_id)
    return nil unless project
    return nil unless current_user.can_view_enrollment_details_for?(project) || current_user.can_view_limited_enrollment_details_for?(project)

    # Load all enrollments for the client, skipping visibility check since we'll filter by project below,
    # and we know the user has enrollment access in this project already. This is to avoid n+1
    enrollments = load_ar_association(client, :enrollments_with_exits)

    # Filter down by project and date
    enrollments.filter do |en|
      en.open_on_date?(open_on_date) && en.project_pk.to_s == project_id.to_s
    end.min_by { |e| [e.entry_date, e.id] }
  end

  def arel
    Hmis::ArelHelper.instance
  end
end
