###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::ReportComponents::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds) { create :grda_warehouse_data_source }
  let!(:c1) { create :hud_client, data_source: ds }
  let!(:o1) { create :hud_organization, data_source: ds }
  let!(:p1) { create :hud_project, data_source: ds, organization: o1 }
  let!(:e1) { create :hud_enrollment, data_source: ds, project: p1, client: c1, relationship_to_hoh: 1, household_id: '123' }
  let!(:coc1) { create :hud_project_coc, data_source: ds, project_id: p1.project_id, state: 'MA' }
  let!(:p2) { create :hud_project, data_source: ds, organization: o1 }
  let!(:e2) { create :hud_enrollment, data_source: ds, project: p2, client: c1, relationship_to_hoh: 1, household_id: '123' }
  let!(:coc2) { create :hud_project_coc, data_source: ds, project_id: p2.project_id, state: 'MA' }
  let!(:p3) { create :hud_project, data_source: ds, organization: o1 }
  let!(:e3) { create :hud_enrollment, data_source: ds, project: p3, client: c1, relationship_to_hoh: 1, household_id: '123' }
  let!(:coc3) { create :hud_project_coc, data_source: ds, project_id: p3.project_id, state: 'MA' }
  let(:a) { create :csg_engage_agency }
  let(:program1) { create :csg_engage_program, agency: a }
  let(:program2) { create :csg_engage_program, agency: a }
  let!(:pm1) { create :csg_engage_program_mapping, project: p1, program: program1 }
  let!(:pm2) { create :csg_engage_program_mapping, project: p2, program: program1 }
  let!(:pm3) { create :csg_engage_program_mapping, project: p3, program: program2 }
  let!(:credential) do
    MaReports::CsgEngage::Credential.create!(
      username: '',
      active: false,
      endpoint: 'https://www.example.com',
      additional_headers: { 'hour' => 4 },
      slug: 'csg_engage_endpoint',
      password: 'test',
    )
  end

  before(:each) do
    WebMock.allow_net_connect!(net_http_connect_on_start: true)
    stub_request(:any, /https:\/\/www\.example\.com\/.*/).to_return_json(body: { 'ok' => true })
  end

  describe 'running tests' do
    it 'should run and cleanup on subsequent runs correctly' do
      report = MaReports::CsgEngage::Report.build(a)
      expect(report.program_reports.count).to eq(2)

      report.run

      expect(WebMock).to have_requested(
        :post,
        'https://www.example.com/Import',
      ).times(2)

      [program1, program2].each do |p|
        pr = report.program_reports.find_by(program_id: p.id)
        expect(pr).to have_attributes(
          raw_result: '{"ok":true}',
          json_result: { 'ok' => true },
          error_data: nil,
          warning_data: nil,
          started_at: be_present,
          completed_at: be_present,
          failed_at: nil,
          imported_program_name: p.csg_engage_name,
          imported_import_keyword: p.csg_engage_import_keyword,
          cleared_at: nil,
        )
        expect(pr.program_mappings).to eq(p.program_mappings)
      end

      # Should delete the previous runs before running again

      MaReports::CsgEngage::Report.build(a).run

      expect(WebMock).to have_requested(
        :post,
        /https:\/\/www\.example\.com\/Delete.*?/,
      ).times(2)

      expect(WebMock).to have_requested(
        :post,
        /https:\/\/www\.example\.com\/Import.*?/,
      ).times(4)
    end
  end
end
