###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectScorecard::Report, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :hud_organization, data_source_id: data_source.id }
  let(:es_project_type) { HudHelper.util.project_type_number_from_code(:es).first }
  let!(:visible_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      organization_id: organization.organization_id,
      project_type: es_project_type,
    )
  end
  let!(:invisible_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      organization_id: organization.organization_id,
      project_type: es_project_type,
    )
  end
  let(:role) { create :role, can_view_assigned_reports: true }

  before do
    # A shared CoC code, so the APR's CoC filter can't be what drops the invisible project
    [visible_project, invisible_project].each do |project|
      create(:hud_project_coc, data_source: data_source, project_id: project.project_id, CoCCode: 'XX-500')
    end
    allow(Reporting::Hud::RunReportJob).to receive(:perform_now) do |_class_name, report_id, **_kwargs|
      HudReports::ReportInstance.find(report_id).update!(state: 'Completed', completed_at: Time.current)
    end
  end

  def hud_reports_for(user, report_name)
    HudReports::ReportInstance.where(user_id: user.id, report_name: report_name)
  end

  [:acl, :legacy].each do |mode|
    context "for a viewable project group containing a project the user cannot see, with #{mode} access" do
      let(:user) { create(mode == :acl ? :acl_user : :user) }
      let(:project_group) { create(:project_group, projects: [visible_project, invisible_project]) }
      let(:report) do
        described_class.create!(
          user: user,
          project_group: project_group,
          start_date: Date.new(2024, 10, 1),
          end_date: Date.new(2025, 9, 30),
        )
      end

      before do
        grant_project_access(user, role, [visible_project], mode: mode)
        grant_project_group_access(user, role, [project_group], mode: mode)
      end

      it 'limits the APR and SPM to the group projects the user can report on' do
        # The stubbed report job leaves the APR and SPM without cells
        allow(report).to receive(:answer).and_return(0)

        report.run_and_save!

        apr = hud_reports_for(user, HudApr.current_generator(report: :apr).title).sole
        spm = hud_reports_for(user, HudSpmReport.current_generator.title).sole
        expect(apr.project_ids).to eq [visible_project.id]
        expect(spm.project_ids).to eq [visible_project.id]
      end
    end
  end
end
