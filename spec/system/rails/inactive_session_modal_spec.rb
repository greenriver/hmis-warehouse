###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# A token inside the warning window that keepalive can't extend is what a gone Keycloak session looks
# like: oauth2-proxy keeps forwarding the old token, so keepalive reports the same short expiry.
RSpec.feature 'inactive session modal', type: :rails_system do
  include JwtAuthenticationHelper

  let(:user) { create :user }

  before do
    allow(user).to receive(:training_required?).and_return(false)
    allow(user).to receive(:pending_compliance_requirements).and_return([])
    allow(User).to receive(:find_or_create_from_jwt).and_return(user)
  end

  it 'says the session can\'t be extended when keepalive returns the same short expiry', :jwt_only, js: true do
    # Inside the 5-minute warning window, with room for a slow page boot.
    token = sign_in(user, expires_at: 4.minutes.from_now)
    page.driver.add_headers('X-Forwarded-Access-Token' => token)

    visit root_path
    # Wait out Bootstrap's fade so the click lands on the button, not the backdrop.
    find('#inactive-session-modal .modal.show', wait: 15)
    sleep 0.5
    click_link "I'm still here"

    expect(page).to have_content("Your session can't be extended")
    expect(page).to have_no_link("I'm still here")
    click_button 'Close'
    expect(page).to have_no_content("Your session can't be extended")
  end
end
