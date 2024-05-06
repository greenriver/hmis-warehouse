module GraphqlPermissionChecker
  # Does the current user have the given permission on entity?
  #
  # @param context [GraphQL::Query::Context] current query context
  # @param permission [Symbol] :can_do_foo
  # @param entity [#record] Client, project, etc
  def self.current_permission_for_context?(context, permission:, entity:)
    current_user = context[:current_user]
    return false unless current_user&.present?

    # Just return false if we don't have this permission at all for anything
    return false unless current_user.send("#{permission}?")

    loader, subject = current_user.entity_access_loader_factory(entity) do |record, association|
      if record.association(association).loaded?
        record.public_send(association)
      else
        context.dataloader.with(Sources::ActiveRecordAssociation, association).load(record)
      end
    end
    raise "Missing loader for #{entity.class.name}##{entity.id}" unless loader

    context.dataloader.with(Sources::UserEntityAccessSource, loader).load([subject, permission])
  end
end
