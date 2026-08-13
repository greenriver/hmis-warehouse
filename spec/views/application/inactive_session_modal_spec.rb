###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application/_inactive_session_modal', type: :view do
  let(:user) { create(:user) }

  before do
    allow(Translation).to receive(:translate) { |key| key }
    # current_user and inactive_session_countdown_values are controller helper_methods, absent from
    # the view verifying double, so stubbing them needs without_partial_double_verification.
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:inactive_session_countdown_values).and_return(session_remaining_secs_value: 2220)
    end
  end

  def modal_node
    render
    Nokogiri::HTML(rendered).at_css('#inactive-session-modal')
  end

  it 'seeds the modal with the current user and the auth arm countdown values' do
    node = modal_node

    expect(node['data-inactive-session-modal-initial-user-id-value']).to eq(user.id.to_s)
    expect(node['data-inactive-session-modal-session-remaining-secs-value']).to eq('2220')
  end
end
