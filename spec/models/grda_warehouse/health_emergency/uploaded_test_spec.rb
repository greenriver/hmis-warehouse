###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HealthEmergency::UploadedTest, type: :model do
  it 'saves an unmatched row (no client) without raising a presence error' do
    uploaded_test = described_class.new(first_name: 'Unmatched', last_name: 'Person', tested_on: Date.current, test_result: 'Negative', test_location: 'Clinic A')

    expect(uploaded_test.save).to eq(true)
    expect(uploaded_test.errors[:client]).to be_empty
  end
end
