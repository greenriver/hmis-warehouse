####
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
##

# Factory to resolve the user access loader for a given entity. It also resolves
# the entity that should be passed to the loader. A resolver blocker is used to
# traverse associations as, in the case of graphql, another data loader would be
# used to resolve the association.
#
# It's up to the caller to actually invoke the loader with the resolved entity to
# perform the access check.
#
# @example
#   factory = Hmis::EntityAccessLoaderFactory.new(user)
#   loader, entity = factory.perform(project) do |record, association|
#     # resolve an entity association. In graphql, a data loader would be used
#     association.send(record)
#   end
#   # resolve a user's permission on project through the loader. Loader.fetch() would
#   # be used to called for many projects
#   allowed = loader.fetch_one(entity, :can_do_something)
class Hmis::EntityAccessLoaderFactory
  # @param user [Hmis::User]
  def initialize(user)
    @user = user
  end

  # Given an entity, return a tuple of the loader and the entity to check against
  #
  # @param entity [#entity_record] active record entity
  # @yieldparam [#entity_record] record
  # @yieldparam [Symbol] association name
  # @yieldreturn [#resolved, nil] the association (record.association)
  # @return [Array<Hmis::BaseLoader, #entity>]
  def perform(entity, &block)
    if entity.new_record?
      resolve_new_record(entity, safety: 0, &block)
    else
      resolve_entity(entity, safety: 0, &block)
    end
  end

  protected

  def resolve_entity(entity, safety:, &block)
    check_safety(safety)

    loader = case entity
    when Hmis::Hud::Client
      Hmis::Hud::ClientAccessLoader
    when Hmis::Hud::Project
      Hmis::Hud::ProjectAccessLoader
    when Hmis::Hud::Organization
      Hmis::Hud::OrganizationAccessLoader
    when GrdaWarehouse::DataSource
      Hmis::DataSourceAccessLoader
    end
    if loader
      [loader.new(@user), entity]
    else
      # recurse
      resolve_association(entity, safety: safety + 1, &block)
    end
  end

  # follow the association chain for entities that don't have their own data loader
  def resolve_association(entity, safety:, &block)
    check_safety(safety)

    resolved = case entity
    when Hmis::File
      # Files are always linked to a client, and optionally link to a specific
      # enrollment. If the file is linked to an enrollment, access to the file
      # should be limited based on access to that enrollment.
      entity.enrollment_id ? block.call(entity, :enrollment) : block.call(entity, :client)
    when Hmis::Hud::Enrollment
      if entity.in_progress?
        block.call(entity, :wip)
      else
        block.call(entity, :project)
      end
    # when Hmis::Hud::CustomAssessment
    #   if entity.in_progress?
    #     block.call(entity, :wip)
    #   else
    #     block.call(entity, :enrollment)
    #   end
    else
      resolve_through_project(entity, &block)
    end

    return nil unless resolved

    if resolved.new_record?
      resolve_new_record(resolved, safety: safety + 1, &block)
    else
      resolve_entity(resolved, safety: safety + 1, &block)
    end
  end

  # For new records we rely on the caller pre-populating specific associations for
  # us to check
  # FIXME: This is fragile. A more robust approach would be for the caller to check
  # the permissions on the associations directly
  def resolve_new_record(entity, safety:, &block)
    check_safety(safety)

    # The client access loader can handle new records directly
    return [Hmis::Hud::ClientAccessLoader.new(@user), entity] if entity.is_a?(Hmis::Hud::Client)

    resolved = case entity
    when Hmis::File
      # Files are always linked to a client, and optionally link to a specific
      # enrollment. If the file is linked to an enrollment, access to the file
      # should be limited based on access to that enrollment.
      entity.enrollment_id ? block.call(entity, :enrollment) : block.call(entity, :client)
    when Hmis::Hud::Enrollment
      # on new enrollments, we check both direct project assoc and wip
      # to eventually arrive at the project
      if entity.in_progress?
        block.call(entity, :wip)
      else
        block.call(entity, :project)
      end
    when Hmis::Hud::HmisService, Hmis::Hud::Service, Hmis::Hud::CustomService
      # This will cascade to enrollment.project
      block.call(entity, :enrollment)
    when Hmis::Hud::Project
      # for new projects, check the organization
      block.call(entity, :organization)
    when Hmis::Hud::Organization
      # for new organizations, check the data_source
      block.call(entity, :data_source)
    else
      resolve_through_project(entity, &block)
    end
    resolved ? resolve_entity(resolved, safety: safety + 1, &block) : nil
  end

  def resolve_through_project(entity, &block)
    return unless entity.is_a?(ApplicationRecord)

    entity.class.reflect_on_association(:project) ? block.call(entity, :project) : nil
  end

  def check_safety(safety)
    raise 'safety count exceeded' if safety > 5
  end
end
