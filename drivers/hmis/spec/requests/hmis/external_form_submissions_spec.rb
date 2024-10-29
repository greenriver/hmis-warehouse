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
    Hmis::Form::Instance.create!(definition: fd, entity: p1, active: true)
    fd
  end

  before(:each) do
    hmis_login(user)
  end

  def perform_query(filters: {})
    response, result = post_graphql({ id: p1.id, formDefinitionIdentifier: definition.identifier, filters: filters }) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'project', 'externalFormSubmissions', 'nodes')
  end

  context 'when user lacks can_manage_external_form_submissions at p1' do
    before(:each) { remove_permissions(access_control, :can_manage_external_form_submissions) }
    it 'should not resolve external form submissions at p1' do
      results = perform_query
      expect(results).to be_empty
    end
    it 'should not resolve external form submissions at p1, even if user has perm at another project' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      create_access_control(hmis_user, p2, with_permission: [:can_manage_external_form_submissions, :can_view_project])

      results = perform_query
      expect(results).to be_empty
    end
  end

  it 'should resolve external form submissions' do
    submission = create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight)
    filters = { 'status' => 'new', submitted_date: today.strftime('%Y-%m-%d') }
    expected = {
      'id' => submission.id.to_s,
      'values' => { 'your_name' => 'value' },
    }
    result = perform_query(filters: filters)
    expect(result).to contain_exactly(expected)
  end

  it 'should not resolve submissions if External Form definition is inactive' do
    definition.instances.first.update!(active: false)

    results = perform_query
    expect(results).to be_empty
  end

  context 'when there are several external forms' do
    let!(:definition_2) do
      fd = create(:hmis_external_form_definition)
      Hmis::Form::Instance.create!(definition: fd, entity: p1, active: true)
      fd
    end

    let!(:sub1) { create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight) }
    let!(:sub1_spam) { create(:hmis_external_form_submission, definition: definition, submitted_at: today.midnight, spam_score: 0) }
    let!(:sub2) { create(:hmis_external_form_submission, definition: definition_2, submitted_at: today.midnight) }
    let!(:sub2_spam) { create(:hmis_external_form_submission, definition: definition_2, submitted_at: today.midnight, spam_score: 0) }

    it 'should return all, including spam, when include_spam filter is passed' do
      response, result = post_graphql({ id: p1.id, formDefinitionIdentifier: definition.identifier }) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodesCount')).to eq(1) # doesn't include spam

      filters = { 'includeSpam' => true }
      variables = {
        id: p1.id,
        formDefinitionIdentifier: definition.identifier,
        filters: filters,
      }
      response, result = post_graphql(variables) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'project', 'externalFormSubmissions', 'nodesCount')).to eq(2) # includes spam
    end
  end
end
