###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::HmisDataQualityToolReportPolicy, type: :model do
  def dq_tool_report(owner)
    HmisDataQualityTool::Report.create!(
      user_id: owner.id,
      report_name: HmisDataQualityTool::Report.untranslated_title,
      manual: true,
      question_names: [],
    )
  end

  shared_examples 'HMIS DQ tool run access' do
    it 'allows the owner\'s run when the tool is granted' do
      grant_hud_report(user, HmisDataQualityTool::Report.url)
      policy = user.policy_for(dq_tool_report(user))

      expect(policy).to be_instance_of(described_class)
      expect(policy.can_view?).to be(true)
    end

    it 'denies the owner\'s run when only a HUD report is granted' do
      grant_hud_report(user, 'hud_reports/aprs')
      apr_run = create(:hud_reports_report_instance, user: user, report_name: HudApr::Generators::Apr::Fy2026::Generator.title)

      expect(user.policy_for(apr_run).can_view?).to be(true)
      expect(user.policy_for(dq_tool_report(user)).can_view?).to be(false)
    end

    it 'follows can_view_all_reports, not can_view_all_hud_reports, for another user\'s run' do
      grant_hud_report(user, HmisDataQualityTool::Report.url, role: create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))
      own_run = dq_tool_report(user)
      other_run = dq_tool_report(create(:user))

      expect(user.policy_for(own_run).can_view?).to be(true)
      expect(user.policy_for(other_run).can_view_definition?).to be(true)
      expect(user.policy_for(other_run).can_view?).to be(false)
    end

    it 'allows another user\'s run with can_view_all_reports' do
      grant_hud_report(user, HmisDataQualityTool::Report.url, role: create(:role, can_view_assigned_reports: true, can_view_all_reports: true))

      expect(user.policy_for(dq_tool_report(create(:user))).can_view?).to be(true)
    end
  end

  context 'with an acl user' do
    let(:user) { create(:acl_user) }

    include_examples 'HMIS DQ tool run access'
  end

  context 'with a legacy user' do
    let(:user) { create(:user) }

    include_examples 'HMIS DQ tool run access'
  end
end
