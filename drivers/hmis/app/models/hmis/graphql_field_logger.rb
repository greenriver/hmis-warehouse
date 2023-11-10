###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::GraphqlFieldLogger
  # @param [Hmis::ActivityLog] record
  def initialize(record)
    @record = record
    @collection = {}
  end

  # @param [Hash] ActiveSupport::Notification payload
  def capture_event(payload)
    field = payload.fetch(:field)
    return if field.name == '__typename'

    object = payload.fetch(:object)
    return unless object.is_a?(Types::BaseObject)

    object_identity = object.activity_log_object_identity
    return unless object_identity

    key = "#{object.class.graphql_name}/#{object_identity}"
    @collection[key] ||= []
    @collection[key].push(field.name)
    true
  end

  def finalize!
    @record.update!(resolved_fields: @collection)
  end
end
