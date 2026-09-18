###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Export::RestrictedClientPiiTransform, type: :model do
  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:source_ds) { create(:source_data_source) }
  let!(:aged_source) { create(:grda_warehouse_hud_client, data_source: source_ds, FirstName: 'Zzaged', MiddleName: 'Q', LastName: 'Zzout', NameSuffix: 'Jr', SSN: '999887777', SSNDataQuality: 1) }
  let!(:aged_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, FirstName: 'Zzaged', MiddleName: 'Q', LastName: 'Zzout', NameSuffix: 'Jr', SSN: '999887777', SSNDataQuality: 1) }
  let!(:current_source) { create(:grda_warehouse_hud_client, data_source: source_ds, FirstName: 'Zzcurrent', LastName: 'Zzout', SSN: '111223333', SSNDataQuality: 1) }
  let!(:current_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, FirstName: 'Zzcurrent', LastName: 'Zzout', SSN: '111223333', SSNDataQuality: 1) }

  let(:export) { build(:grda_warehouse_hmis_export, hash_status: 1, faked_pii: false) }
  let(:redacted) { GrdaWarehouse::PiiProvider::REDACTED }

  subject(:transform) { described_class.new(export: export) }

  before do
    link(aged_destination, aged_source)
    link(current_destination, current_source)
    GrdaWarehouse::InactiveClient.create!(client_id: aged_source.id, marked_on: Date.current, last_activity_on: 10.years.ago.to_date, retention_years: 7)
  end

  def link(destination, source)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.PersonalID)
  end

  it 'redacts name and SSN, and keeps DOB, on the destination of a retention-marked source' do
    row = transform.process(aged_destination)

    expect(row).to have_attributes(FirstName: redacted, MiddleName: redacted, LastName: redacted, NameSuffix: redacted, SSN: nil, SSNDataQuality: 99)
    expect(row.DOB).to eq(aged_destination.DOB)
  end

  it 'covers destination rows only: a marked source row, which the exporter never emits, passes through' do
    expect(transform.process(aged_source)).to have_attributes(FirstName: 'Zzaged', SSN: '999887777')
  end

  it 'issues no queries per row once the sets are loaded' do
    transform

    expect do
      transform.process(aged_destination)
      transform.process(current_destination)
    end.not_to make_database_queries
  end

  it 'leaves an unmarked client in the same export untouched' do
    expect(transform.process(current_destination)).to have_attributes(FirstName: 'Zzcurrent', LastName: 'Zzout', SSN: '111223333', SSNDataQuality: 1)
  end

  it 'leaves a marked client alone in a hashed export' do
    hashed = described_class.new(export: build(:grda_warehouse_hmis_export, hash_status: 4, faked_pii: false))

    expect(hashed.process(aged_destination)).to have_attributes(FirstName: 'Zzaged', SSN: '999887777')
  end
end
