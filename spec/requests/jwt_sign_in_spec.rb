###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JWT Sign In Helper', type: :request do
  let(:user) { create(:user) }

  describe 'sign_in helper' do
    it 'authenticates user with JWT token' do
      sign_in(user)

      # Token is automatically included in headers via the helper
      get edit_account_path
      expect(response).to be_successful
    end

    it 'sets JWT headers for subsequent requests' do
      sign_in(user)

      # First request
      get edit_account_path
      expect(response).to be_successful

      # Second request - headers should persist
      get edit_account_path
      expect(response).to be_successful
    end

    it 'allows multiple users to be signed in sequentially' do
      user1 = create(:user)
      user2 = create(:user)

      sign_in(user1)
      get edit_account_path
      expect(response).to be_successful

      sign_in(user2)
      get edit_account_path
      expect(response).to be_successful
    end
  end
end
