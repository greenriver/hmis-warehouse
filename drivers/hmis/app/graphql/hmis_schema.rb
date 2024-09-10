###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisSchema < GraphQL::Schema
  mutation(Types::HmisSchema::MutationType)
  query(Types::HmisSchema::QueryType)

  trace_with(GraphqlTraceBehavior)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  # - after upgrade to Rails 7.1 we could replace Dataloader with AsyncDataloader for performance
  #   https://graphql-ruby.org/dataloader/async_dataloader
  use GraphQL::Dataloader

  disable_introspection_entry_points unless Rails.env.development?

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, _obj, _ctx)
    # TODO: Implement this method
    # to return the correct GraphQL object type for `obj`
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, _type_definition, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end

  # Raise exception when `authorized?` returns false for an object (Default behavior is to return nil)
  # This is an unexpected error because we should always be doing permission checks
  # (e.g. applying viewable_by scope) before trying to resolve something.
  def self.unauthorized_object(error)
    raise GraphQL::UnauthorizedError, "#{error.type.graphql_name}##{error.object&.id} failed authorization check"
  end

  # Return nil for anauthorized fields. This is expeced in some cases, for example non-summary fields on Enrollment.
  def self.unauthorized_field(_error)
    nil
  end
end
