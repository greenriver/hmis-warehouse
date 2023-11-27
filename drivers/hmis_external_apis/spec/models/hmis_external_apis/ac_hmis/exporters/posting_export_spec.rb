###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::PostingExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:p1) { create(:hmis_hud_project, data_source: ds) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: client, project: p1) }
  let!(:enrollment2) { create(:hmis_hud_enrollment, data_source: ds, household_id: enrollment.household_id, relationship_to_hoh: 2, project: p1) }
  let!(:posting) { create(:hmis_external_api_ac_hmis_referral_posting, status: 'accepted_status', household_id: enrollment.household_id, project: p1, data_source: ds) }

  # cruft: postings with excluded statuses
  let!(:posting2) { create(:hmis_external_api_ac_hmis_referral_posting, status: 'assigned_status', household_id: enrollment.household_id, project: p1, data_source: ds) }
  let!(:posting3) { create(:hmis_external_api_ac_hmis_referral_posting, status: 'accepted_pending_status', project: p1, data_source: ds) }
  let!(:posting4) { create(:hmis_external_api_ac_hmis_referral_posting, status: 'denied_pending_status', project: p1, data_source: ds) }

  let(:subject) { HmisExternalApis::AcHmis::Exporters::PostingExport.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets postings' do
    subject.run!
    expect(subject.send(:postings).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
    expect(result.first['PersonalID']).to eq(client.warehouse_id.to_s)
    expect(result.first['EnrollmentID']).to eq(enrollment.id.to_s)
    expect(result.first['EntityPostingID']).to eq(posting.identifier)
  end

  it 'excludes internal postings' do
    posting.update(identifier: nil)

    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(0)
  end

  it 'includes closed postings' do
    posting.update(status: 'closed_status')

    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
    expect(result.first['EntityPostingID']).to eq(posting.identifier)
  end
end
