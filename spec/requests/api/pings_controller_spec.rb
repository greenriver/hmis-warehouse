###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PingsController, type: :request, if: AuthMethod.jwt? do
  let(:user) { create(:user) }

  it 'returns 200 for an authenticated user' do
    sign_in(user)

    get '/api/ping'

    expect(response).to have_http_status(:ok)
    expect(response.body).to be_empty
  end

  it 'returns 500 for a tokenless probe' do
    get '/api/ping'
    expect(response).to have_http_status(:error)
  end
end
