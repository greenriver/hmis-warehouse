###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::LinksController, type: :request do
  let(:user) { create(:user) }
  let(:link_params) { { link: { label: 'Help desk', url: 'https://example.com/help', location: 'footer' } } }

  before do
    user.legacy_roles << role
    sign_in user
  end

  context 'with can_manage_config' do
    let(:role) { create(:role, can_manage_config: true) }

    it 'creates a link' do
      expect { post admin_links_path, params: link_params }.to change(Link, :count).by(1)
    end
  end

  context 'with only can_edit_users' do
    let(:role) { create(:role, can_edit_users: true) }

    it 'does not create a link' do
      expect { post admin_links_path, params: link_params }.not_to change(Link, :count)
    end
  end
end
