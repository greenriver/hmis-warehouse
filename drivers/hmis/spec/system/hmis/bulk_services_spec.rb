#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Hmis Form behavior', type: :system do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:bednight_service_type) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) }
  let(:service_form_definition) { Hmis::Form::Definition.where(role: :SERVICE).first }
  let!(:instance) { create(:hmis_form_instance, definition: service_form_definition, entity: p1, custom_service_type: bednight_service_type) }

  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Josiah' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Joshua' }
  let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Josephine' }

  let(:today) { Date.current }

  before(:each) do
    sign_in(hmis_user)
    visit "/projects/#{p1.id}"
    click_link 'Bed Nights'
  end

  describe 'bed nights' do
    it 'correctly searches, enrolls, and assigns service to clients' do
      find('[name="search client"]').fill_in(with: 'Jos')
      find_button('Search').trigger(:click)
      expect(all('tbody tr').count).to eq(3) # all 3 clients returned because their names match the pattern

      find('input[type="checkbox"][aria-label="select all"]', visible: :all).trigger(:click)
      click_button 'Enroll (3) + Assign (3)'
      assert_text 'Assigned' # wait for it to process

      # Find the indices of the two columns we want to check
      header_cells = all('thead th')
      last_bed_night_date_index = header_cells.find_index { |cell| cell.text == 'Last Bed Night Date' }
      assign_bed_night_index = header_cells.find_index { |cell| cell.text == "Assign Bed Night for #{today.strftime('%m/%d/%Y')}" }
      expect(last_bed_night_date_index).not_to be_nil
      expect(assign_bed_night_index).not_to be_nil

      # Verify that all 3 rows have the expected attributes
      all('tbody tr').each do |row|
        # Check the "Last Bed Night Date" column
        last_bed_night_date = row.all('td')[last_bed_night_date_index].text
        expect(last_bed_night_date).to eq("Today (#{today.strftime('%m/%d/%Y')})")

        # Check the "Assign Bed Night for mm/dd/yyyy" column
        assign_button = row.all('td')[assign_bed_night_index].find('button')
        expect(assign_button.text).to eq('Assigned')
      end

      services = Hmis::Hud::Service.joins(enrollment: [:project, :client]).all
      expect(services.count).to eq(3)
      expect(services.pluck(:project_pk).uniq.sole).to eq(p1.id)
      expect(services.pluck(:personal_id).to_set).to eq([c1.personal_id, c2.personal_id, c3.personal_id].to_set)
      expect(services.pluck(:date_provided).uniq.sole).to eq(today)
      expect(services.pluck(:type_provided).uniq.sole).to eq(bednight_service_type.hud_type_provided)
    end

    context 'when a client has an alert' do
      let!(:alert) { create :hmis_client_alert, client: c1, note: 'Important note!', created_by: hmis_user }

      before(:each) do
        find('[name="search client"]').fill_in(with: 'Jos')
        find_button('Search').trigger(:click)
        rows = all('tbody tr')
        expect(rows.count).to eq(3)
      end

      it 'correctly displays alert for client when you enroll individually' do
        # Find the row where "First name" is "Josiah"
        target_row = all('tbody tr').find do |row|
          row.find('td', text: 'Josiah', match: :prefer_exact)
        end
        expect(target_row).not_to be_nil

        # Verify the Assign button has an icon with an aria-label "Client has an active alert"
        assign_button = target_row.find('button', text: 'Enroll + Assign')
        alert_icon = assign_button.find('[aria-label="Client has an active alert"]')
        expect(alert_icon).not_to be_nil

        # When you click the assign button for an individual row, the alert pops up
        assign_button.trigger(:click)
        assert_text 'Client Alert for Josiah'
        assert_text 'Important note'

        # But you can still click to continue and add the service
        click_button 'Add Bed Night'
        expect(target_row.find('button', text: 'Assigned')).not_to be_nil
        c1.reload
        expect(c1.services.sole.type_provided).to eq(bednight_service_type.hud_type_provided)
        expect(c1.services.sole.project).to eq(p1)
      end

      it 'does not block you from enrolling in bulk' do
        # TODO - maybe this was what was causing confusion?
        find('input[type="checkbox"][aria-label="select all"]', visible: :all).trigger(:click)
        click_button 'Enroll (3) + Assign (3)' # Does not pop up the alert when processing in bulk
        assert_text 'Assigned' # wait for it to process
        expect(Hmis::Hud::Service.count).to eq(3)
      end
    end
  end
end
