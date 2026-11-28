###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'JavaScript Functionality Test', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:agency) { create :agency }
  let!(:role) { create :admin_role }
  let!(:user) { create :acl_user, agency: agency }
  let!(:collection) { create :collection }

  before do
    collection.set_viewables({ data_sources: GrdaWarehouse::DataSource.all.pluck(:id) })
    setup_access_control(user, role, collection)
  end

  describe DatePickerInput, js: true do
    before { sign_in_user(user) }

    it 'Correctly adjusts dates' do
      visit datepicker_style_guide_path

      # Test that the date picker is present
      expect(page).to have_css('.datepicker')

      # Fill in the datepicker field
      picker = find('input.datepicker')
      expected_date = 'May 7, 2024'
      [
        'May 7, 2024',
        '05/07/2024',
        '5/7/2024',
        '05-07-2024',
        '5-7-2024',
        '2024-05-07',
        '2024/05/07',
        '05/07/24',
        '5/7/24',
        '05-07-24',
        '5-7-24',
        # Tempus Dominus alone misread these as other valid-looking dates
        'May 7 2024',
        'may 7, 2024',
        'MAY 7 2024',
        '7 May 2024',
      ].each do |date|
        fill_in picker[:id], with: date
        picker.trigger(:blur)
        # Ensure the date was set correctly
        expect(picker.value).to eq(expected_date)
      end

      # check the four-letter month
      sept_expected_date = 'Sep 1, 2025'
      ['Sept 1, 2025'].each do |date|
        fill_in picker[:id], with: date
        picker.trigger(:blur)
        expect(picker.value).to eq(sept_expected_date)
      end

      # check the full month too
      ['September 1, 2025', 'Sept 1 2025', 'Sept. 1, 2025'].each do |date|
        fill_in picker[:id], with: date
        picker.trigger(:blur)
        expect(picker.value).to eq(sept_expected_date)
      end

      # Impossible or unrecognized dates stay as typed and are flagged, rather than rolling over
      # (2/30 becoming Mar 1) or being guessed at
      ['2/30/2024', '13/01/2024', '5/7', 'garbage'].each do |date|
        fill_in picker[:id], with: date
        picker.trigger(:blur)
        expect(picker.value).to eq(date)
        expect(picker[:class]).to include('is-invalid')
        expect(picker['aria-invalid']).to eq('true')
        expect(find(id: picker['aria-describedby'])).to have_text('Enter a date like')
      end

      fill_in picker[:id], with: '5/7/2024'
      picker.trigger(:blur)
      expect(picker.value).to eq(expected_date)
      expect(picker[:class]).not_to include('is-invalid')
      expect(picker['aria-invalid']).to be_nil
      expect(picker['aria-describedby']).to be_nil

      # A two-digit year more than 10 years ahead belongs to the last century. Tempus Dominus alone
      # reads anything up to 68 as 20xx, so a birth date typed as "1/2/50" landed in 2050.
      far_year = Date.current.year + 20
      fill_in picker[:id], with: "1/2/#{far_year.to_s.last(2)}"
      picker.trigger(:blur)
      expect(picker.value).to eq("Jan 2, #{far_year - 100}")
    end

    it 'names the calendar button and popup after the field' do
      visit datepicker_style_guide_path
      picker = find('input.datepicker')
      toggle = find('button.icon-calendar')

      expect(toggle['aria-label']).to eq('Choose Date')
      expect(toggle['aria-haspopup']).to eq('dialog')
      expect(toggle['aria-expanded']).to eq('false')

      toggle.click
      expect(page).to have_css('button.icon-calendar[aria-expanded="true"]')
      # The popup is labelled after a short delay once it opens; have_css waits for it
      expect(page).to have_css('.tempus-dominus-widget.show[role="dialog"][aria-label="Choose Date"]')
      within('.tempus-dominus-widget.show') do
        ['previous', 'next', 'today', 'clear', 'close'].each do |action|
          control = find("[data-action=\"#{action}\"]", visible: :all)
          expect(control[:role]).to eq('button')
          expect(control['aria-label']).to be_present
        end
        expect(find('[data-action="changeCalendarView"]')[:role]).to eq('button')
      end

      toggle.click
      expect(page).to have_css('button.icon-calendar[aria-expanded="false"]')

      # Tempus Dominus renames the button on every change; it keeps the field's name
      fill_in picker[:id], with: '12/31/2024'
      picker.trigger(:blur)
      expect(page).to have_css('button.icon-calendar[aria-label="Choose Date, Dec 31, 2024"]')
    end

    it 'clears the error when a flagged date is emptied' do
      visit datepicker_style_guide_path
      picker = find('input.datepicker')

      # Emptied by typing, with no date picked before
      fill_in picker[:id], with: '2/30/2024'
      picker.trigger(:blur)
      expect(picker[:class]).to include('is-invalid')
      fill_in picker[:id], with: ''
      picker.trigger(:blur)
      expect(picker[:class]).not_to include('is-invalid')
      expect(picker['aria-invalid']).to be_nil

      # Emptied with the popup's Clear button, after a date was picked
      fill_in picker[:id], with: '5/7/2024'
      picker.trigger(:blur)
      fill_in picker[:id], with: '2/30/2024'
      picker.trigger(:blur)
      expect(picker[:class]).to include('is-invalid')
      find('button.icon-calendar').click
      find('.tempus-dominus-widget [data-action="clear"]').click
      expect(picker.value).to eq('')
      expect(picker[:class]).not_to include('is-invalid')
      expect(picker['aria-invalid']).to be_nil
    end

    it 'blocks submitting a form with a flagged date' do
      visit datepicker_style_guide_path
      picker = find('input.datepicker')

      # The style guide form is simple_form (novalidate) and posts to a path that only accepts GET,
      # so a submit that got through would leave this page
      fill_in picker[:id], with: '2/30/2024'
      picker.trigger(:blur)
      click_button 'Create'
      # Focus moving back to the field shows the guard ran (reportValidity)
      expect(page).to have_css("##{picker[:id]}:focus")
      expect(page).to have_current_path(datepicker_style_guide_path)
      expect(picker.value).to eq('2/30/2024')
      expect(page).to have_button('Create', disabled: false)
    end

    it 'explains a blocked submit when the flagged date is hidden' do
      visit datepicker_style_guide_path
      picker = find('input.datepicker')

      fill_in picker[:id], with: '2/30/2024'
      picker.trigger(:blur)
      # Stands in for a collapsed panel or inactive tab
      page.execute_script("document.querySelector('input.datepicker').closest('.input-group').style.display = 'none'")

      message = accept_alert { click_button 'Create' }
      expect(message).to include('Enter a date like')
      expect(page).to have_current_path(datepicker_style_guide_path)
    end

    it 'lets a formnovalidate button submit with a flagged date' do
      visit datepicker_style_guide_path
      picker = find('input.datepicker')

      fill_in picker[:id], with: '2/30/2024'
      picker.trigger(:blur)
      # Point the form at a GET-only page so the submit that gets through lands somewhere
      page.execute_script("document.querySelector('input.datepicker').form.setAttribute('method', 'get')")
      click_button 'Cancel'
      expect(page).to have_current_path(/mock_2/, url: true)
    end
  end
end
