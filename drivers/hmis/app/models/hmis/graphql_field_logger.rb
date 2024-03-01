###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::GraphqlFieldLogger
  attr_accessor :last_event_at
  def initialize
    @collection = {}
  end

  # @param [Types::BaseField] field
  # @param [Object] object from graphql resolver
  def capture_event(field, object)
    self.last_event_at = Time.current
    return if field.name == '__typename'

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

  def activity_log_attrs
    {
      resolved_fields: collection,
      resolved_at: last_event_at,
    }
  end
end
