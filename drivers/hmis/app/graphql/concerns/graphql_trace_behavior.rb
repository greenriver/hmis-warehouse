module GraphqlTraceBehavior
  def execute_field(field:, query:, ast_node:, arguments:, object:)
    result = super
    context_activity_logger(query.context).capture_event(field, object)
    result
  end

  # the logger is packed into the context
  def context_activity_logger(context)
    context.fetch(:activity_logger)
  end
end
