require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'file upload setup'

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }

  let(:test_input) do
    {
      client_id: c1.id,
      file_blob_id: blob.id,
      file_tags: [tag.id],
    }
  end

  let(:full_test_input) do
    test_input.merge(
      enrollment_id: e1.id,
      effective_date: Date.today,
      expiration_date: Date.tomorrow,
      confidential: true,
    )
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UploadClientFile($input: UploadClientFileInput!) {
        uploadClientFile(input: $input) {
          client {
            id
            files {
              nodes {
                id
                url
                name
                contentType
                effectiveDate
                expirationDate
                confidential
                createdAt
                updatedAt
              }
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
  end

  def call_mutation(input)
    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq 200
    files = result.dig('data', 'uploadClientFile', 'client', 'files', 'nodes')
    errors = result.dig('data', 'uploadClientFile', 'errors')
    [files, errors]
  end

  # ! This has the right logic to test file creation, but we're removing this mutation so it's skipped now. Leaving this as a reference for the processor tests
  xdescribe 'creation tests' do
    it 'should create the file correctly' do
      files, errors = call_mutation(full_test_input)
      expect(errors).to be_empty
      expect(files).to contain_exactly(
        include(
          'contentType' => blob.content_type,
          'name' => blob.filename,
          'url' => be_present,
          'effectiveDate' => Date.today.strftime('%Y-%m-%d'),
          'expirationDate' => Date.tomorrow.strftime('%Y-%m-%d'),
          'confidential' => true,
        ),
      )
      expect(Hmis::File.all).to contain_exactly(
        have_attributes(
          id: files.first['id'].to_i,
          name: full_test_input[:name] || blob.filename,
          effective_date: full_test_input[:effective_date],
          expiration_date: full_test_input[:expiration_date],
          confidential: full_test_input[:confidential],
          client: have_attributes(id: full_test_input[:client_id]),
          enrollment: have_attributes(id: full_test_input[:enrollment_id]),
          client_file: have_attributes(
            blob: have_attributes(
              id: full_test_input[:file_blob_id],
            ),
          ),
        ),
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
