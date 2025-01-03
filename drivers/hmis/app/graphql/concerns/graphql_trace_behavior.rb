###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
