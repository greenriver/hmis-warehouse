###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      ['September 1, 2025'].each do |date|
        fill_in picker[:id], with: date
        picker.trigger(:blur)
        expect(picker.value).to eq(sept_expected_date)
      end
    end
  end
end
