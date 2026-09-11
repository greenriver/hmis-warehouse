###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  include_context 'DQ Tool test setup'

  describe 'global overlap checks' do
    let!(:report_project) { create_project(project_type: 0) } # ES entry/exit
    let!(:outside_project) { create_project(project_type: 0) } # ES entry/exit, not passed to the report
    let!(:client) { create_client_with_warehouse_link }

    def client_item(report)
      HmisDataQualityTool::Client.find_by(report_id: report.id, client_id: client.id)
    end

    def enable_global_overlap_checks
      HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', global_overlap_checks: true)
    end

    after do
      HmisDataQualityTool::Goal.where(coc_code: 'MA-500').destroy_all
    end

    context 'with an ES enrollment overlapping one in a project outside the report' do
      before do
        create_enrollment(client: client, project: report_project, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-15'.to_date)
        @outside_enrollment = create_enrollment(client: client, project: outside_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date)
      end

      context 'when the flag is off' do
        before { @report = setup_report([report_project.id]) }

        it 'ignores the enrollment outside the report' do
          expect_result(key: :overlapping_entry_exit_issues, invalid_count: 0)
        end
      end

      context 'when the flag is on' do
        before do
          enable_global_overlap_checks
          @report = setup_report([report_project.id])
        end

        it 'flags the overlap' do
          expect_result(key: :overlapping_entry_exit_issues, invalid_count: 1)
        end

        it 'stores the outside enrollment with its project id and dates but no project name' do
          pair = client_item(@report).overlapping_entry_exit_details.first
          outside, inside = pair.partition { |en| en['outside_report'] }.map(&:first)

          expect(outside).to include(
            'id' => @outside_enrollment.id,
            'project_id' => outside_project.id,
            'entry_date' => '2022-12-01',
            'exit_date' => '2023-01-15',
          )
          expect(outside).not_to have_key('project')
          expect(inside).to include('project' => report_project.ProjectName)
          expect(inside.keys).not_to include('outside_report', 'project_id')
        end

        describe 'display-time project name resolution' do
          let(:item) { client_item(@report) }
          let(:pii_policy) { user_with_client_access.reporting_policy_for_project(project_id: report_project.id, client_id: item.destination_client_id_for_pii) }

          def displayed_outside_entry(user)
            project_names = @report.outside_report_project_names(items: [item], user: user)
            details = item.download_value(:overlapping_entry_exit_details, pii_policy: pii_policy, project_names: project_names)
            details.first.detect { |en| en['outside_report'] }
          end

          it 'shows the real project name to a user who can report on that project' do
            outside = displayed_outside_entry(user_with_client_access)

            expect(outside['project']).to eq(outside_project.ProjectName)
            expect(outside).not_to have_key('project_id')
          end

          it 'shows the real project name to a legacy (non-ACL) user whose access group includes that project' do
            legacy_user = create(:user)
            legacy_user.legacy_roles << create(:role, name: 'DQ Tool Test Legacy Role', can_view_assigned_reports: true, can_view_projects: true)
            legacy_user.add_viewable(outside_project)

            outside = displayed_outside_entry(legacy_user)

            expect(outside['project']).to eq(outside_project.ProjectName)
          end

          it 'redacts the project name for a user whose access is limited to the report project' do
            limited_user = create(:acl_user)
            limited_role = create(:role, name: 'DQ Tool Test Role - One Project', can_view_assigned_reports: true, can_view_projects: true, can_view_project_related_filters: true)
            one_project_collection = create(:collection)
            one_project_collection.set_viewables({ projects: [report_project.id] })
            setup_access_control(limited_user, limited_role, one_project_collection)

            outside = displayed_outside_entry(limited_user)

            expect(outside['project']).to eq('(Project Name Redacted)')
            expect(outside).not_to have_key('project_id')
          end
        end
      end
    end

    context 'when the only overlapping enrollments are both outside the report' do
      before do
        other_outside_project = create_project(project_type: 0)
        create_enrollment(client: client, project: report_project, entry_date: '2022-10-01'.to_date, exit_date: '2022-10-15'.to_date)
        create_enrollment(client: client, project: outside_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date)
        create_enrollment(client: client, project: other_outside_project, entry_date: '2022-12-10'.to_date, exit_date: '2023-01-20'.to_date)
        enable_global_overlap_checks
        @report = setup_report([report_project.id])
      end

      it 'does not flag the client' do
        expect_result(key: :overlapping_entry_exit_issues, invalid_count: 0)
      end
    end

    context 'with a moved-in PSH enrollment overlapping one in a PSH project outside the report' do
      before do
        psh_project = create_project(project_type: 3)
        outside_psh_project = create_project(project_type: 3)
        create_enrollment(client: client, project: psh_project, entry_date: '2022-11-15'.to_date, exit_date: '2023-01-15'.to_date, move_in_date: '2022-12-01'.to_date)
        create_enrollment(client: client, project: outside_psh_project, entry_date: '2022-11-20'.to_date, exit_date: '2023-02-01'.to_date, move_in_date: '2022-12-10'.to_date)
        enable_global_overlap_checks
        @report = setup_report([psh_project.id])
      end

      it 'flags the overlap' do
        expect_result(key: :overlapping_post_move_in_issues, invalid_count: 1)
      end
    end

    context 'with NbN bed nights falling inside an ES enrollment outside the report' do
      before do
        nbn_project = create_project(project_type: 1)
        nbn_enrollment1 = create_enrollment(client: client, project: nbn_project, entry_date: '2022-12-14'.to_date, exit_date: '2022-12-15'.to_date)
        nbn_enrollment2 = create_enrollment(client: client, project: nbn_project, entry_date: '2022-12-17'.to_date, exit_date: '2022-12-18'.to_date)
        create_enrollment(client: client, project: outside_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date)
        create_bed_night_service(enrollment: nbn_enrollment1, date: '2022-12-14'.to_date)
        create_bed_night_service(enrollment: nbn_enrollment2, date: '2022-12-17'.to_date)
        enable_global_overlap_checks
        @report = setup_report([nbn_project.id])
      end

      it 'flags the overlap' do
        expect_result(key: :overlapping_nbn_issues, invalid_count: 1)
      end
    end

    context 'with the overlapping enrollment in a different data source' do
      before do
        other_data_source = create(:source_data_source)
        other_organization = create(:hud_organization, data_source: other_data_source)
        other_project = create(:hud_project, project_type: 0, organization: other_organization, data_source: other_data_source, ContinuumProject: 1)
        create(:hud_project_coc, project: other_project, ProjectID: other_project.ProjectID, data_source: other_data_source, coc_code: 'MA-500')
        other_source_client = create(:hud_client, data_source: other_data_source, dob: client.DOB)
        create(:warehouse_client, destination_id: client.destination_client.id, source_id: other_source_client.id)
        other_enrollment = create(
          :hud_enrollment,
          client: other_source_client,
          project: other_project,
          data_source: other_data_source,
          entry_date: '2022-12-01'.to_date,
          relationship_to_ho_h: 1,
          enrollment_coc: 'MA-500',
        )
        create(:hud_exit, enrollment: other_enrollment, exit_date: '2023-01-15'.to_date, data_source: other_data_source, personal_id: other_source_client.PersonalID)
        create_enrollment(client: client, project: report_project, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-15'.to_date)
        enable_global_overlap_checks
        @report = setup_report([report_project.id])
      end

      it 'flags the overlap' do
        expect_result(key: :overlapping_entry_exit_issues, invalid_count: 1)
      end
    end
  end
end
