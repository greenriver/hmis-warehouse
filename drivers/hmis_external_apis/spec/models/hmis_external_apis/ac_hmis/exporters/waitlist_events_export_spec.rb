###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::WaitlistEventsExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: ds) }
  let!(:unit_group) { create(:hmis_unit_group, project: project) }

  let!(:destination_client) { create(:grda_warehouse_hud_client) }
  let!(:client_proxy) { create(:hmis_ce_client_proxy, client: destination_client) }

  let!(:pool) do
    create(:hmis_ce_match_candidate_pool).tap do |p|
      unit_group.update!(candidate_pool: p)
    end
  end

  let!(:event) do
    create(:hmis_ce_match_candidate_event, candidate_pool: pool, client_proxy: client_proxy, event_name: 'add')
  end

  let(:subject) { described_class.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets waitlist events' do
    subject.run!
    expect(CSV.parse(output, headers: true).length).to eq(1)
  end

  it 'makes a csv with expected values' do
    subject.run!
    result = CSV.parse(output, headers: true)
    row = result.first

    expect(row['ID']).to eq("#{event.id}_#{unit_group.id}")
    expect(row['PersonalID']).to eq(destination_client.id.to_s)
    expect(row['ProjectID']).to eq(project.id.to_s)
    expect(row['ProjectName']).to eq(project.project_name)
    expect(row['UnitGroupID']).to eq(unit_group.id.to_s)
    expect(row['UnitGroupName']).to eq(unit_group.name)
    expect(row['EventName']).to eq('add')
    expect(row['CreatedAt']).to eq(event.created_at.strftime('%Y-%m-%d %H:%M:%S'))
  end
end
