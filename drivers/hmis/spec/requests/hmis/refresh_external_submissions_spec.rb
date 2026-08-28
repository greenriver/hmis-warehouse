###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Refresh External Submissions', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation RefreshExternalSubmissions {
        refreshExternalSubmissions {
          success
        }
      }
    GRAPHQL
  end

  before(:each) { hmis_login(user) }

  def perform_mutation
    post_graphql { mutation }
  end

  context 'when the user can manage external form submissions at a project' do
    let!(:access_control) do
      create_access_control(hmis_user, p1, with_permission: [:can_manage_external_form_submissions, :can_view_project])
    end

    it 'enqueues the consume job' do
      expect do
        response, result = perform_mutation
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'refreshExternalSubmissions', 'success')).to eq(true)
      end.to have_enqueued_job(HmisExternalApis::ConsumeExternalFormSubmissionsJob)
    end
  end

  context 'when the user lacks can_manage_external_form_submissions' do
    let!(:access_control) do
      create_access_control(hmis_user, p1, without_permission: :can_manage_external_form_submissions)
    end

    it 'denies access and does not enqueue the job' do
      expect { expect_access_denied perform_mutation }.
        not_to have_enqueued_job(HmisExternalApis::ConsumeExternalFormSubmissionsJob)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
