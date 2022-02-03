###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

describe ClaimsReporting::MedicalClaim, type: :model do
  it 'skips invalid service end before start' do
    File.open('drivers/claims_reporting/spec/fixtures/files/medical_claim.csv') do |file|
      described_class.import_csv_data(file, filename: 'medical_claim.csv', replace_all: true)

      expect(described_class.pluck(:claim_number).map(&:to_i).sort).to eq([2, 3])
    end
  end
end
