###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::OauthClientConnection, type: :model do
  let(:fake_token) { 'deadbeefdeadbeefdeadbeefdeadbeef' }
  let(:host) { 'example.com' }
  let(:client_id) { '1234567890' }
  let(:client_secret) { 'secretsecretsecret' }
  let(:token_url) { 'https://example.com/oauth2/v1/token' }

  let(:subject) do
    HmisExternalApis::OauthClientConnection.new(
      client_id: client_id,
      client_secret: client_secret,
      token_url: token_url,
      base_url: "https://#{host}/",
      scope: 'API_TEST',
    )
  end

  before(:each) do
    # mock successful oauth
    body = {
      "access_token": fake_token,
      "token_type": 'Bearer',
      "expires_in": 3600,
      "refresh_token": fake_token,
      "scope": subject.scope,
    }.to_json
    stub_request(:post, 'https://example.com/oauth2/v1/token')
      .to_return(status: 200, body: body,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'supports a get' do
    path = 'test/resources/1'
    stub_request(:get, "#{subject.base_url}#{path}")
      .to_return(status: 200, body: { helloWorld: 1 }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    result = subject.get(path)
    expect(result.http_status).to eq(200)
    expect(result.parsed_body).to include('helloWorld')
  end

  it 'handles errors' do
    path = 'test/resources/2'
    stub_request(:get, "#{subject.base_url}#{path}")
      .to_return(status: 404, body: nil, headers: {})

    result = subject.get(path)
    expect(result.http_status).to eq(404)
    expect(result.body).to be_blank
    expect(result.parsed_body).to be_blank
    expect(result.error_type).to eq('OAuth2::Error')
  end

  it 'supports a post' do
    path = 'test/resources'
    expected_status = 200
    stub_request(:post, "#{subject.base_url}#{path}")
      .to_return(status: expected_status, body: nil, headers: {})
    result = subject.post(path, { 'hello' => 'world' })
    expect(result.http_status).to eq(expected_status)
  end

  it 'supports a patch' do
    path = 'test/resources/1'
    expected_status = 200
    stub_request(:patch, "#{subject.base_url}#{path}")
      .to_return(status: expected_status, body: nil, headers: {})
    result = subject.patch(path, { 'hello' => 'world' })
    expect(result.http_status).to eq(expected_status)
  end
end
