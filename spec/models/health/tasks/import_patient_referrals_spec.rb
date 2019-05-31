require 'rails_helper'

RSpec.describe Health::Tasks::ImportPatientReferrals, type: :model do
  before(:each) do
    @importer = Health::Tasks::ImportPatientReferrals.new(directory: 'spec/fixtures/files/health/referral')
  end

  it 'loads the active/new referrals' do
    @importer.process_files ['first_full.csv']
    expect(Health::PatientReferral.count).to eq 2
  end

  it 'doesn\'t duplicate referrals' do
    @importer.process_files ['first_full.csv']
    @importer.process_files ['first_full.csv']
    expect(Health::PatientReferral.count).to eq 2
  end

  it 'reactivates removed referrals' do
    @importer.process_files ['first_full.csv']
    client = Health::PatientReferral.find_by(medicaid_id: 123)
    client.update!(rejected: true, rejected_reason: 1, removal_acknowledged: true)

    @importer.process_files ['first_full.csv']
    expect(Health::PatientReferral.count).to eq 2

    client.reload
    expect(client.rejected).to eq false
  end
end
