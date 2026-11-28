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
    end
  end
end
