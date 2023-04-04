###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GraphqlHelpers
  HMIS_ORIGIN = 'https://hmis.dev.test:5173/'
  HMIS_HOSTNAME = 'hmis.dev.test'

  def post_graphql(variables = {})
    variables = variables.deep_transform_keys { |k| k.is_a?(Symbol) ? k.to_s.camelize(:lower) : k }
    headers = { 'CONTENT_TYPE' => 'application/json', 'ORIGIN' => HMIS_ORIGIN }
    post '/hmis/hmis-gql', params: { query: yield, variables: variables }.to_json, headers: headers
    # puts response.body
    if response.code == '200'
      result = JSON.parse(response.body) # , object_class: OpenStruct
      raise result.to_h['errors'].first['message'] unless result.to_h['errors'].nil? || result.to_h['errors'].empty?

      [response, result.to_h]
    else
      body = JSON.parse(response.body)
      [response, body.to_h]
    end
  end

  def scalar_fields(typ)
    fields = []

    field_types = typ.respond_to?(:fields) ? typ.fields : typ.type&.of_type&.fields
    field_types.each do |name, field|
      next if field.type.list? || field.type.respond_to?(:fields) || (field.type.respond_to?(:of_type) && field.type.of_type.respond_to?(:fields))

      fields << name
    end
    fields.join("\n")
  end

  def error_fields
    <<~ERRORS
      errors {
        id
        linkId
        attribute
        message
        fullMessage
        type
        severity
        readableAttribute
        __typename
      }
    ERRORS
  end
end
