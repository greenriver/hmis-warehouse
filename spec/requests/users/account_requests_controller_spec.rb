###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::AccountRequestsController, :jwt_only, type: :request do
  def request_account_available!(value)
    GrdaWarehouse::Config.first_or_create.update!(request_account_available: value)
  end

  context 'when account requests are enabled' do
    before { request_account_available!(true) }

    it 'renders the form for an unauthenticated visitor' do
      get new_users_account_request_path

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when account requests are disabled' do
    before { request_account_available!(false) }

    it 'does not render the form' do
      get new_users_account_request_path

      expect(response).not_to have_http_status(:ok)
    end
  end
end
