###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::Project::DataQualitiesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/project/data_quality', name: 'Project Data Quality') }
  let!(:visible_group) { create(:project_group) }
  let!(:invisible_group) { create(:project_group) }

  before do
    collection.set_viewables({ reports: [report.id], project_groups: [visible_group.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'POST create' do
    it 'queues no report for a project group the user cannot see' do
      post warehouse_reports_project_data_quality_path,
           params: {
             project_data_quality: { start: 1.month.ago.to_date, end: Date.current, generate: 1, email: 0 },
             project_group: { visible_group.id => 1, invisible_group.id => 1 },
           }

      report_class = GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive
      expect(report_class.where(project_group_id: visible_group.id)).to exist
      expect(report_class.where(project_group_id: invisible_group.id)).not_to exist
    end
  end
end
