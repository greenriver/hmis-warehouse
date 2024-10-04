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
    raise "Missing loader for #{entity.class.name}##{entity.id}" unless loader && subject

    # subject is expected to be one of Client, Project, Organization, or Data Source.
    data_source_id = if subject.is_a? GrdaWarehouse::DataSource
      subject.id
    else
      subject.data_source_id
    end

    # Return false because even if the user has permission to view this record in another hmis data source,
    # they should not be able to resolve it in the context of the hmis they are currently using (hmis_data_source_id).
    return false unless current_user.hmis_data_source_id == data_source_id

    context.dataloader.with(Sources::UserEntityAccessSource, loader).load([subject, permission])
  end
end
