###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::GraphqlFieldLogger
  def initialize
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

    field_name = object.activity_log_field_name(field.name)
    @collection[key].push(field_name) if field_name
    true
  end

  def collection
    @collection.transform_values { |v| v.sort.uniq }
  end
end
