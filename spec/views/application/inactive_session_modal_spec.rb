###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Exercises the partial's countdown seed on both arms by stubbing AuthMethod.jwt?, so it runs under
# either CI boot with no `if: AuthMethod.jwt?` guard. The url helpers it renders (session_keepalive_path,
# destroy_user_session_path) exist on both arms, so the stubbed arm never mismatches routing.
RSpec.describe 'application/_inactive_session_modal', type: :view do
  let(:user) { create(:user) }

  before do
    allow(Translation).to receive(:translate) { |key| key }
    # current_user / user_session_expires_at are controller helper_methods absent on the bare view
    # double, so partial-double verification must be relaxed to stub them.
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end
  end

  def modal_node
    render
    Nokogiri::HTML(rendered).at_css('#inactive-session-modal')
  end

  context 'on the JWT arm' do
    let(:expires_at) { 37.minutes.from_now }

    before do
      allow(AuthMethod).to receive(:jwt?).and_return(true)
      without_partial_double_verification do
        allow(view).to receive(:user_session_expires_at).and_return(expires_at)
      end
    end

    it 'seeds the countdown from the token expiry rather than the Devise default' do
      node = modal_node

      expect(node['data-inactive-session-modal-session-expires-at-value']).to eq(expires_at.to_i.to_s)
      devise_default = Time.current.to_i + Devise.timeout_in.in_seconds.to_i
      expect(node['data-inactive-session-modal-session-expires-at-value'].to_i).not_to be_within(30).of(devise_default)
    end
  end

  context 'on the Devise arm' do
    before { allow(AuthMethod).to receive(:jwt?).and_return(false) }

    it 'does not seed a token expiry and keeps the Devise lifetime' do
      node = modal_node

      expect(node['data-inactive-session-modal-session-expires-at-value']).to be_nil
      expect(node['data-inactive-session-modal-session-lifetime-secs-value']).to eq(Devise.timeout_in.in_seconds.to_s)
    end
  end
end
