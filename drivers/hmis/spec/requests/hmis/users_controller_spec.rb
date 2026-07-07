###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::UsersController, type: :request do
  include_context 'hmis base setup'

  describe 'GET /hmis/user.json' do
    context 'when authenticated' do
      before do
        hmis_login(user)
        get hmis_user_path
      end

      it 'includes trueUser matching the signed-in user' do
        parsed = JSON.parse(response.body)
        expect(parsed['trueUser']).to eq('id' => hmis_user.id.to_s, 'name' => hmis_user.name)
      end

      it 'includes a primaryIdp key (nil under Devise, since there is no connector)' do
        parsed = JSON.parse(response.body)
        expect(parsed).to have_key('primaryIdp')
        expect(parsed['primaryIdp']).to be_nil
      end
    end

    context 'when not authenticated' do
      it 'omits trueUser and primaryIdp' do
        get hmis_user_path

        parsed = JSON.parse(response.body)
        expect(parsed['trueUser']).to be_nil
        expect(parsed).not_to have_key('primaryIdp')
      end
    end
  end
end
