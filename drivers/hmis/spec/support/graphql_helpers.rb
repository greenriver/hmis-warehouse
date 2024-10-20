###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GraphqlHelpers
  HMIS_ORIGIN = 'https://hmis.dev.test:5173/'
  HMIS_HOSTNAME = 'hmis.dev.test'

  def post_graphql(variables = {})
    variables = transform_graphql_variables(variables)
    params = { query: yield, variables: variables }.compact_blank
    post '/hmis/hmis-gql', params: params.to_json, headers: graphql_post_headers
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

  def post_graphql_single(query:, variables: {}, headers: {}, operation_name: nil)
    variables = transform_graphql_variables(variables)
    params = { query: query, variables: variables, operationName: operation_name }.compact_blank
    post '/hmis/hmis-gql', params: params.to_json, headers: graphql_post_headers(headers)
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

  def post_graphql_multi(queries:, headers: {})
    params = queries.map do |query|
      {
        variables: transform_graphql_variables(query[:variables]),
        operationName: query[:operation_name],
        query: query[:query],
      }.compact_blank
    end
    post '/hmis/hmis-gql', params: { _json: params }.to_json, headers: graphql_post_headers(headers)
    if response.code == '200'
      results = JSON.parse(response.body) # , object_class: OpenStruct
      results.each do |result|
        raise result.to_h['errors'].first['message'] unless result.to_h['errors'].nil? || result.to_h['errors'].empty?
      end

      [response, results]
    else
      body = JSON.parse(response.body)
      [response, body.to_h]
    end
  end

  def graphql_post_headers(headers = {})
    headers.merge({ 'CONTENT_TYPE' => 'application/json', 'ORIGIN' => HMIS_ORIGIN })
  end

  def transform_graphql_variables(variables)
    variables.deep_transform_keys { |k| k.is_a?(Symbol) ? k.to_s.camelize(:lower) : k }
  end

  def scalar_fields(typ)
    fields = []

    field_types = typ.respond_to?(:fields) ? typ.fields : typ.type&.of_type&.fields
    field_types.each do |name, field|
      field_type = field.type
      # Get the "base" field type, cutting through the NonNull and List wrappers
      field_type = field_type.of_type while field_type.respond_to?(:of_type)

      # If base type is an object, skip it
      next if field_type.respond_to?(:fields)
      # If field accepts arguments, skip it
      next if field.arguments.any?

      fields << name
    end
    fields.join("\n")
  end

  def error_fields
    <<~ERRORS
      errors {
        id
        linkId
        recordId
        attribute
        message
        fullMessage
        type
        severity
        readableAttribute
        data
        __typename
      }
    ERRORS
  end

  def expect_gql_error(arr, message: nil)
    response, result = arr
    error_message = result.dig('errors', 0, 'message')
    expect(response.status).to eq(500), result.inspect
    expect(error_message).to be_present
    expect(error_message).to match(/#{message}/) if message.present?
  end

  def expect_access_denied(arr)
    # expect default message from access_denied! helper
    expect_gql_error(arr, message: 'access denied')
  end
end
