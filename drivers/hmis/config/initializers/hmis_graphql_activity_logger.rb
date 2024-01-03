###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

ActiveSupport::Notifications.subscribe(/execute_field\.graphql/) do |_name, _start, _finish, _id, payload|
  next unless payload

  # the logger is packed into the context
  object = payload.fetch(:object)
  context = object.context
  logger = context.fetch(:activity_logger)
  logger.capture_event(payload)
end
