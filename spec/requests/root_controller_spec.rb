###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RootController, type: :request do
  it 'renders the sign-in page as HTML' do
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it 'returns 406 for a JSON request instead of raising a missing template error' do
    get root_path, headers: { 'Accept' => 'application/json' }
    expect(response).to have_http_status(:not_acceptable)
  end
end
