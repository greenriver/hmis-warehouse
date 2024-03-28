###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'External Referral Form Submissions', type: :request do
  include_context 'hmis base setup'
  subject(:query) do
    %(
      query projectExternalFormSubmissions(
        $id: ID!
        $limit: Int = 10
        $offset: Int = 0
        $formDefinitionIdentifier: ID!
        $filters: ExternalFormSubmissionFilterOptions
      ) {
        project(id: $id) {
          id
          externalFormSubmissions(
            limit: $limit
             offset: $offset
             formDefinitionIdentifier: $formDefinitionIdentifier
             filters: $filters
          ) {
            nodes {
              id
              customDataElements {
                key
              }
            }
          }
        }
      }
    )
  end
  let(:today) { Date.current }

  let!(:access_control) do
    create_access_control(hmis_user, p1, with_permission: [:can_manage_external_form_submissions, :can_view_project])
  end

  let!(:form_definition) do
    fd = create(:hmis_external_form_definition)
    HmisExternalApis::PublishExternalFormsJob.new.perform(fd.id)
    fd.reload
    Hmis::Form::Instance.create!(definition: fd, entity: p1, active: true)
    fd
  end

  before(:each) do
    hmis_login(user)
  end

  it 'should resolve external form submissions' do
    submission = create(:hmis_external_form_submission, definition: form_definition, submitted_at: today.midnight)
    submission.process_custom_data_elements!(form_definition: form_definition)
    filters = { 'status' => 'new', submitted_date: today.strftime('%Y-%m-%d') }
    variables = {
      id: p1.id,
      formDefinitionIdentifier: form_definition.identifier,
      filters: filters,
    }
    response, result = post_graphql(variables) { query }
    expect(response.status).to eq 200
    expected = {
      'id' => submission.id.to_s,
      'customDataElements' => [{ 'key' => 'your_name' }],
    }
    expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodes')).to contain_exactly(expected)
  end
end
