###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Migration::InitialMciUniqueIdCreationJob, type: :job do
  let(:job) { HmisExternalApis::AcHmis::Migration::InitialMciUniqueIdCreationJob.new }
  let!(:remote_credential) { create(:ac_hmis_warehouse_credential) }

  let!(:ds1) { create :hmis_data_source }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, personal_id: Hmis::Hud::Base.generate_uuid }
  let!(:umci1) { create(:mci_unique_id_external_id, source: c1, value: '100', remote_credential: remote_credential) }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, personal_id: '123abc' }
  let!(:c3) { create :hmis_hud_client, data_source: ds1, personal_id: '200' }
  let!(:c4) { create :hmis_hud_client, data_source: ds1, personal_id: '300' }
  let!(:umci4) { create(:mci_unique_id_external_id, source: c4, value: '300', remote_credential: remote_credential) }
  let!(:c5) { create :hmis_hud_client, data_source: ds1, personal_id: '400' }
  let!(:umci5) { create(:mci_unique_id_external_id, source: c5, value: '500', remote_credential: remote_credential) }
  let!(:c6) { create :hmis_hud_client, data_source: ds1, personal_id: '600' }

  it 'creates MCI unique IDs' do
    expect(c1.ac_hmis_mci_unique_id&.value).to eq('100')
    expect(c2.ac_hmis_mci_unique_id&.value).to be_nil
    expect(c3.ac_hmis_mci_unique_id&.value).to be_nil
    expect(c4.ac_hmis_mci_unique_id&.value).to eq('300')
    expect(c5.ac_hmis_mci_unique_id&.value).to eq('500')
    expect(c6.ac_hmis_mci_unique_id&.value).to be_nil

    job.perform
    [c1, c2, c3, c4, c5, c6].each(&:reload)

    expect(c1.ac_hmis_mci_unique_id&.value).to eq('100') # unchanged
    expect(c2.ac_hmis_mci_unique_id&.value).to be_nil # ignored because non-numeric
    expect(c3.ac_hmis_mci_unique_id&.value).to eq('200') # new
    expect(c4.ac_hmis_mci_unique_id&.value).to eq('300') # unchanged
    expect(c5.ac_hmis_mci_unique_id&.value).to eq('500') # unchanged
    expect(c6.ac_hmis_mci_unique_id&.value).to eq('600') # new
    expect(c6.ac_hmis_mci_unique_id.created_at).to be_present
    expect(c6.ac_hmis_mci_unique_id.updated_at).to be_present
  end
end
