# frozen_string_literal: true

module GraphqlHelpers
  HMIS_ORIGIN = 'https://hmis.dev.test:5173/'
  HMIS_HOSTNAME = 'hmis.dev.test'

  def post_graphql(variables = {})
    variables = variables.deep_transform_keys { |k| k.to_s.camelize(:lower) }
    headers = { 'CONTENT_TYPE' => 'application/json', 'ORIGIN' => HMIS_ORIGIN }
    post '/hmis/hmis-gql', params: { query: yield, variables: variables }.to_json, headers: headers
    puts response.body
    if response.code == '200'
      result = JSON.parse(response.body)
      raise result.to_h['errors'].first['message'] unless result.to_h['errors'].nil? || result.to_h['errors'].empty?

      [response, result.to_h]
    else
      body = JSON.parse(response.body)
      [response, body.to_h]
    end
  end
end
