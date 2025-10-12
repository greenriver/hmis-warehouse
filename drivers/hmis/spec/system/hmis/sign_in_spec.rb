###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'HMIS Sign In', type: :system do
  include_context 'hmis base setup'

  # could parse CAPYBARA_APP_HOST
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }

  context 'When not signed in' do
    it 'shows sign-in form' do
      visit '/'
      expect(page).to have_content 'Sign In'
    end
  end

  context 'When signed in' do
    before(:each) { sign_in(hmis_user) }

    it 'Loads client search' do
      expect(page).to have_content 'Clients'
    end

    context 'and signed out' do
      before(:each) { sign_out }
      it 'shows sign-in form' do
        expect(page).to have_content 'Sign In'
      end
    end
  end
end
