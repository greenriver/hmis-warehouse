###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CurrentWaitlistsExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: ds) }
  let!(:unit_group) { create(:hmis_unit_group, project: project) }
  let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: project) }

  let!(:destination_client) { create(:grda_warehouse_hud_client) }
  let!(:client_proxy) { create(:hmis_ce_client_proxy, client: destination_client) }

  let!(:pool) do
    create(:hmis_ce_match_candidate_pool).tap do |p|
      unit_group.update!(candidate_pool: p)
    end
  end

  let!(:candidate) do
    create(:hmis_ce_match_candidate, candidate_pool: pool, client_proxy: client_proxy, priority_scores: [5, 4, 3])
  end

  let(:subject) { described_class.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'exports current waitlist candidates' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
  end

  it 'includes expected fields and priority scores' do
    subject.run!
    result = CSV.parse(output, headers: true)
    row = result.first

    expect(row['ID']).to eq("#{candidate.id}_#{unit_group.id}")
    expect(row['PersonalID']).to eq(destination_client.id.to_s)
    expect(row['ProjectID']).to eq(project.id.to_s)
    expect(row['ProjectName']).to eq(project.project_name)
    expect(row['UnitGroupID']).to eq(unit_group.id.to_s)
    expect(row['UnitGroupName']).to eq(unit_group.name)
    expect(row['CreatedAt']).to eq(candidate.created_at.strftime('%Y-%m-%d %H:%M:%S'))
    expect(row['UpdatedAt']).to eq(candidate.updated_at.strftime('%Y-%m-%d %H:%M:%S'))
    expect(row['PriorityScore1']).to eq('5')
    expect(row['PriorityScore2']).to eq('4')
    expect(row['PriorityScore3']).to eq('3')
  end

  it 'excludes candidates from inactive candidate pools' do
    unit_group.update!(candidate_pool: nil) # remove candidate pool association, rendering the pool inactive
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(0)
  end
end
