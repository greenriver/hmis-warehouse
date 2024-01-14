module GraphqlPermissionChecker
  extend ActiveSupport::Concern

  protected

  # Does the current user have the given permission on entity?
  #
  # @param context [GraphQL::Query::Context] current query context
  # @param permission [Symbol] :can_do_foo
  # @param entity [#record] Client, project, etc
  def current_permission_for_context?(context, permission:, entity:)
    current_user = context[:current_user]
    return false unless current_user&.present?

    # Just return false if we don't have this permission at all for anything
    return false unless current_user.send("#{permission}?")

    loader, subject = current_user.entity_access_loader_factory(entity) do |record, association|
      context.dataloader.with(Sources::ActiveRecordAssociation, association, nil).load(record)
    end
    raise "Missing loader for #{entity.class.name}##{entity.id}" unless loader

    context.dataloader.with(Sources::UserEntityAccessSource, loader).load([subject, permission])
  end
  module_function :current_permission_for_context?
end
