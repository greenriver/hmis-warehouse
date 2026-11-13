###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Raises from a real action so the exception reaches config.exceptions_app; requesting /500 directly
# would be served by public/500.html.
RSpec.describe 'error pages', type: :request do
  # Without these, DebugExceptions renders instead of exceptions_app
  before do
    production_env_config = Rails.application.env_config.merge(
      'action_dispatch.show_exceptions' => :all,
      'action_dispatch.show_detailed_exceptions' => false,
    )
    allow(Rails.application).to receive(:env_config).and_return(production_env_config)
  end

  # If the route and action names drift apart, Rails renders the template implicitly with a 200
  it 'renders the server error page with a 500 status for an unhandled exception' do
    allow(GrdaWarehouse::ContentPage).to receive(:find_by!).and_raise(RuntimeError)

    get content_page_path('any-slug')

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to include('This page generated a server error')
  end

  it 'renders the not found page with a 404 status for a missing record' do
    get content_page_path('no-such-page')

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include('Sorry, we could not find the page you are looking for.')
  end

  it 'renders the unacceptable page with a 422 status for an invalid authenticity token' do
    allow(GrdaWarehouse::ContentPage).to receive(:find_by!).and_raise(ActionController::InvalidAuthenticityToken)

    get content_page_path('any-slug')

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Whoops! Something went wrong with your request...')
  end
end
