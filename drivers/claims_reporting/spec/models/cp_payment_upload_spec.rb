###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

describe ClaimsReporting::CpPaymentUpload, model: :type do
  before(:each) do
    File.open('drivers/claims_reporting/spec/fixtures/files/cp_payment_upload.xlsx') do |xlsx|
      @upload = described_class.create(content: xlsx.read)
    end
  end

  it 'ignores case in headers' do
    expect(@upload.content_as_details).not_to be_nil
  end
end
