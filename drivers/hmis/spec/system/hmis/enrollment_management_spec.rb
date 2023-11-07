require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Enrollment/household management', type: :system do
  include_context 'hmis base setup'
  # could parse CAPYBARA_APP_HOST
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, last_name: 'Aabcdefghij' }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, last_name: 'Klmnopqrs' }
  let!(:unit) { create :hmis_unit, project: p1, user: user }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  before(:each) do
    sign_in(hmis_user)
  end

  context 'An active project' do
    before(:each) do
      click_link 'Projects'
      click_link p1.project_name
      # find('div', text: p1.project_name).click
      click_link 'Enrollments'
    end

    it 'can enroll a client' do
      click_link 'Add Enrollment'
      fill_in 'Search Clients', with: c1.last_name
      click_button 'Search'
      click_button 'Enroll Client'

      fill_in 'Entry Date', with: Date.yesterday.strftime('%m/%d/%Y')
      mui_select 'Self (HoH)', from: 'Relationship to HoH'
      mui_select unit.name, from: 'Unit'
      click_button 'Enroll'

      # FIXME - blocked by Enrollment CoC prompt
      # debug
    end
  end
end
