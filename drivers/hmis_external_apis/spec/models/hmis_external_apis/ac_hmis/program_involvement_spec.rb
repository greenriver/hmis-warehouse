###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::ProgramInvolvement, type: :model do
  describe 'basics' do
    let!(:ds) { create(:hmis_data_source) }
    let(:involvement) { HmisExternalApis::AcHmis::ProgramInvolvement.new({}) }

    before { involvement.validate_request! }

    it 'gracefully handles no inputs' do
      expect(involvement.ok?).to be_falsy
    end

    it 'returns an involvements payload' do
      expect(JSON.parse(involvement.to_json)['involvements']).to eq []
    end
  end

  describe 'request' do
    let!(:ds) { create(:hmis_data_source) }
    let!(:org) { create(:hmis_hud_organization, data_source: ds) }
    let!(:p1) { create(:hmis_hud_project, data_source: ds, organization: org) }
    let!(:p2) { create(:hmis_hud_project, data_source: ds, organization: org) }
    let!(:p3) { create(:hmis_hud_project, data_source: ds, organization: org) }

    let!(:c1) { create(:hmis_hud_client, data_source: ds) }
    let!(:mci_id) do
      external_id = create(:mci_external_id, source: c1)
      external_id.value
    end

    let!(:e1) { create(:hmis_hud_enrollment, data_source: ds, project: p1, client: c1) }
    let!(:e2) { create(:hmis_hud_enrollment, data_source: ds, project: p2, client: c1) }
    let!(:e3) { create(:hmis_hud_enrollment, data_source: ds, project: p3, client: c1) }

    let(:params) do
      {
        start_date: '1990-01-01',
        end_date: '4023-01-01',
        program_ids: [p1.project_id, p2.project_id],
      }
    end

    let(:involvement) { HmisExternalApis::AcHmis::ProgramInvolvement.new(params) }

    before { involvement.validate_request! }

    it 'works' do
      involvements = JSON.parse(involvement.to_json)['involvements']

      expect(involvement).to be_ok
      expect(involvements.length).to eq(2)
      expect(involvements.map { |i| i['mci_id'] }.uniq).to eq([mci_id])
      expect(involvements.map { |i| i['program_id'] }).to contain_exactly(p1.project_id, p2.project_id)
    end

    it 'fails if any projects not found' do
      bad_project_id = 12345
      involvement = HmisExternalApis::AcHmis::ProgramInvolvement.new(params.merge(program_ids: [p1.project_id, bad_project_id]))
      involvement.validate_request!
      expect(involvement).not_to be_ok
      status_message = JSON.parse(involvement.to_json)['status_message']
      expect(status_message).to include(bad_project_id.to_s)
    end
  end
end
