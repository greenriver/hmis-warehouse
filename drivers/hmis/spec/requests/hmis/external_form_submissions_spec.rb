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
            nodesCount
            nodes {
              id
              values
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

  let!(:definition) do
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
    submission = create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight)
    filters = { 'status' => 'new', submitted_date: today.strftime('%Y-%m-%d') }
    variables = {
      id: p1.id,
      formDefinitionIdentifier: definition.identifier,
      filters: filters,
    }
    response, result = post_graphql(variables) { query }
    expect(response.status).to eq 200
    expected = {
      'id' => submission.id.to_s,
      'values' => { 'your_name' => 'value' },
    }
    expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodes')).to contain_exactly(expected)
  end

  context 'when form rule applies to the organization, not the project' do
    let!(:definition) { create :hmis_external_form_definition }
    let!(:rule) { create :hmis_form_instance, definition_identifier: definition.identifier, entity: p1.organization, active: true }

    it 'should return submissions' do
      submission = create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight, raw_data: { 'your_name' => 'ebeneezer' })
      response, result = post_graphql({ id: p1.id, formDefinitionIdentifier: definition.identifier }) { query }
      expect(response.status).to eq 200
      expected = {
        'id' => submission.id.to_s,
        'values' => { 'your_name' => 'ebeneezer' },
      }
      expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodes')).to contain_exactly(expected)
    end
  end

  context 'when there are several external forms' do
    let!(:definition_2) do
      fd = create(:hmis_external_form_definition)
      HmisExternalApis::PublishExternalFormsJob.new.perform(fd.id)
      fd.reload
      Hmis::Form::Instance.create!(definition: fd, entity: p1, active: true)
      fd
    end

    let!(:sub1) { create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight) }
    let!(:sub1_spam) { create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight, spam_score: 0) }
    let!(:sub2) { create(:hmis_external_form_submission, definition: definition_2, submitted_at: today.midnight) }
    let!(:sub2_spam) { create(:hmis_external_form_submission, definition: definition_2, submitted_at: today.midnight, spam_score: 0) }

    it 'should return all, including spam, when include_spam filter is passed' do
      response, result = post_graphql({ id: p1.id, formDefinitionIdentifier: definition.identifier }) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodesCount')).to eq(1) # doesn't include spam

      filters = { 'includeSpam' => true }
      variables = {
        id: p1.id,
        formDefinitionIdentifier: definition.identifier,
        filters: filters,
      }
      response, result = post_graphql(variables) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodesCount')).to eq(1) # includes spam
    end
  end
end
