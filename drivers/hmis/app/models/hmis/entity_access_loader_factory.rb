####
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
##

# Factory returning the user access loader for a given entity
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
    @safety = nil
  end

  # Given an entity, return a tuple of the loader and the entity to resolve
  # @param entity [#entity_record] active record entity
  # # @yieldparam [#entity_record] record
  # # @yieldparam [Symbol] assocation name
  # @return [Array<Hmis::BaseLoader, #entity>]
  def perform(entity, &block)
    @safety ||= 0
    check_safety

    loader = case entity
    when Hmis::Hud::Client
      Hmis::Hud::ClientAccessLoader
    when Hmis::Hud::Project
      Hmis::Hud::ProjectAccessLoader if entity.persisted?
    when Hmis::Hud::Organization
      Hmis::Hud::OrganizationAccessLoader if entity.persisted?
    when GrdaWarehouse::DataSource
      Hmis::DataSourceAccessLoader if entity.persisted?
    end
    if loader
      @safety = nil
      [loader.new(@user), entity]
    else
      # recurse
      resolve_association(entity, &block)
    end
  end

  # follow the association chain for entities that don't have their own data loader
  # or for entities that are not yet persisted
  protected def resolve_association(entity, &block)
    check_safety

    resolved = case entity
    when Hmis::File
      entity.new_record? ? entity.client : block.call(entity, :client)
    when Hmis::Hud::HmisService
      block.call(entity, :enrollment)
    when Hmis::Hud::Project
      entity.organization if entity.new_record?
    when Hmis::Hud::Organization
      entity.data_source if entity.new_record?
    else
      entity.class.reflect_on_association(:project) ? block.call(entity, :project) : nil
    end
    resolved ? perform(resolved, &block) : nil
  end

  protected def check_safety
    @safety += 1
    raise 'safety count exceeded' if @safety > 5
  end
end
