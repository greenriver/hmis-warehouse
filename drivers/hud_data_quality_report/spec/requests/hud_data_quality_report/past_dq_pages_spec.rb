###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Past HUD Data Quality report pages', type: :request do
  let(:user) { create(:acl_user) }
  let(:question_path) { hud_reports_past_dq_question_path(past_dq_id: 0, id: 'Question 1') }

  before { Rails.cache.clear }

  it 'renders a question page for a user granted the DQ definition' do
    grant_hud_report(user, 'hud_reports/dqs')
    sign_in(user)

    get question_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Question 1')
  end

  it 'redirects a user granted only the APR definition' do
    grant_hud_report(user, 'hud_reports/aprs')
    sign_in(user)

    get question_path

    expect(response).to have_http_status(:redirect)
    expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
  end
end
