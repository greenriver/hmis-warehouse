###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Viewing/editing legacy Service records on Enrollment', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 4 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let(:client) { enrollment.client }
  let(:today) { Date.current }

  let!(:flex_funds_service_type) { create :hmis_custom_service_type, data_source: ds1, name: 'Flex Funds' }
  let!(:bed_nights_service_type) { create :hmis_custom_service_type_for_hud_service, data_source: ds1 }

  before(:each) do
    sign_in(hmis_user)
  end

  # Tests behavior when there are no Form Rules enabling any Services in this Project, yet there is Service data that exists.
  # Existing "legacy" Services should remain viewable and editable (both HUD and Custom services).

  context 'when no Service is enabled in the project' do
    def side_nav_elements
      find_all('a[id^="side-nav-"]').map(&:text)
    end

    it 'should not show Service in the project side nav' do
      visit "/projects/#{p1.id}/overview"
      expect(side_nav_elements).not_to include('Services')
    end

    it 'should not show Services in the enrollment side nav' do
      visit "/client/#{client.id}/enrollments/#{enrollment.id}/overview"
      expect(side_nav_elements).not_to include('Services')
    end

    context 'but HUD Service exists (no form processor)' do
      let!(:service) { create(:hmis_hud_service, enrollment: enrollment) }

      it 'should show Services in the project nav' do
        visit "/projects/#{p1.id}/overview"
        expect(side_nav_elements).to include('Services')
      end
      it 'should show Services in the enrollment nav' do
        visit "/client/#{client.id}/enrollments/#{enrollment.id}/overview"
        expect(side_nav_elements).to include('Services')
      end
    end
  end

  context 'when no Service is enabled but Service data exists on the Enrollment' do
    before(:each) { visit "/client/#{client.id}/enrollments/#{enrollment.id}/services" }

    # HUD Service exists with no form processor, should use default service form
    context 'HUD Service exists (no form processor)' do
      let!(:service) { create(:hmis_hud_service, enrollment: enrollment) }

      it 'should not allow adding a new Service' do
        assert_no_text 'Add Service'
      end

      it 'should show legacy HUD Service' do
        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include('Bed Night')
      end

      it 'should allow editing legacy HUD Service' do
        find('tbody').first('tr').trigger(:click)
        assert_text 'Update Service'
        click_button 'Save'
      end
    end

    # HUD Service exists with a form processor, should use specified form for viewing and editing
    context 'HUD Service exists (with form processor)' do
      let(:custom_note_field) { 'Super custom notes field' }
      let!(:cded) { create(:hmis_custom_data_element_definition_for_hud_service_note, data_source: ds1) }
      let(:service_note_item) do
        {
          "type": 'TEXT',
          "link_id": 'note',
          "required": false,
          "text": custom_note_field,
          'mapping': { 'custom_field_key': cded.key },
        }
      end
      # Create retired form definition that's NOT enabled for this project, but IS linked to this service.
      let!(:service_definition) { create(:hmis_service_form, data_source: ds1, status: :retired, append_items: [service_note_item]) }
      let!(:service) { create(:hmis_hud_service, enrollment: enrollment, definition: service_definition) }

      it 'should not allow adding a new Service' do
        assert_no_text 'Add Service'
      end

      it 'should show legacy HUD Service' do
        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include('Bed Night')
      end

      it 'should allow viewing and editing HUD Service with specified form' do
        find('tbody').first('tr').trigger(:click)
        assert_text 'Update Service'
        assert_text custom_note_field # ensure rendering the correct form

        expect do
          fill_in custom_note_field, with: 'Some notes'
          click_button 'Save'
          assert_no_text 'Update Service'
        end.to change(cded.values, :count).by(1)
      end
    end

    # Custom Service exists with a form processor, should use specified form for viewing and editing
    context 'CustomService exists (with form processor)' do
      let(:custom_note_field) { 'Super custom notes field' }
      let!(:cded) { create(:hmis_custom_data_element_definition_for_custom_service_note, data_source: ds1) }
      let(:service_note_item) do
        {
          "type": 'TEXT',
          "link_id": 'note',
          "required": false,
          "text": custom_note_field,
          'mapping': { 'custom_field_key': cded.key },
        }
      end
      # Create retired form definition that's NOT enabled for this project, but IS linked to this service.
      let!(:service_definition) { create(:hmis_service_form, data_source: ds1, status: :retired, append_items: [service_note_item]) }
      let!(:service) { create(:hmis_custom_service, enrollment: enrollment, definition: service_definition, service_type: flex_funds_service_type) }

      it 'should not allow adding a new Service' do
        assert_no_text 'Add Service'
      end

      it 'should show legacy Custom Service' do
        table_row = find('tbody').find_all('tr').sole.text
        expect(table_row).to include('Flex Funds')
      end

      it 'should allow viewing and editing Custom Service with specified form' do
        find('tbody').first('tr').trigger(:click)
        assert_text 'Update Service'
        assert_text custom_note_field # ensure rendering the correct form

        expect do
          fill_in custom_note_field, with: 'Some notes'
          click_button 'Save'
          assert_no_text 'Update Service'
        end.to change(cded.values, :count).by(1)
      end
    end
  end
end
