###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LSA source data download', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:other_user) { create(:acl_user) }
  let(:collection) { create(:collection) }
  let(:export) { create(:grda_warehouse_hmis_export, :with_zip, content_type: 'application/zip') }

  # Baseline: can reach the LSA report pages, but holds no source-data permission.
  let(:permissions) { { can_view_own_hud_reports: true } }
  let(:role) { create(:role, **permissions) }

  # The controller already knows which fiscal year is current (its newest active
  # entry in available_report_versions), so read it from there instead of naming a
  # year here -- adding FY2028 to the controller moves these specs onto it.
  def current_lsa_generator
    controller = HudLsa::LsasController.new
    controller.send(:possible_generator_classes).fetch(controller.default_report_version)
  end

  def create_lsa_report(owner: user, export_record: export, report_class: current_lsa_generator)
    report_class.create!(
      report_name: report_class.title,
      user_id: owner.id,
      export: export_record,
      question_names: report_class.questions.keys,
      options: {
        user_id: owner.id,
        coc_code: 'XX-500',
        coc_codes: ['XX-500'],
        start: Date.new(2024, 10, 1),
        end: Date.new(2025, 9, 30),
        project_ids: [],
      },
    )
  end

  before do
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET download_source_data' do
    let!(:report) { create_lsa_report }

    context 'with can_download_lsa_source_data' do
      let(:permissions) { { can_view_own_hud_reports: true, can_download_lsa_source_data: true } }

      it 'sends the export content' do
        get download_source_data_hud_reports_lsa_path(report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('zip-data')
      end

      it '404s when the report has no export' do
        no_export = create_lsa_report(export_record: nil)

        get download_source_data_hud_reports_lsa_path(no_export)

        expect(response).to have_http_status(:not_found)
      end

      it 'serves a retired fiscal year report' do
        retired = create_lsa_report(report_class: HudLsa::Generators::Fy2024::Lsa)

        get download_source_data_hud_reports_lsa_path(retired)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('zip-data')
      end

      it "404s on another user's report" do
        theirs = create_lsa_report(owner: other_user)

        get download_source_data_hud_reports_lsa_path(theirs)

        expect(response).to have_http_status(:not_found)
      end

      context 'as a report admin' do
        let(:permissions) do
          {
            can_view_own_hud_reports: true,
            can_view_all_hud_reports: true,
            can_download_lsa_source_data: true,
          }
        end

        it "serves another user's report" do
          theirs = create_lsa_report(owner: other_user)

          get download_source_data_hud_reports_lsa_path(theirs)

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq('zip-data')
        end
      end
    end

    # can_download_lsa_source_data is additive -- HudReports::BaseController's
    # require_can_view_hud_reports! still has to be satisfied to reach the action.
    context 'holding can_download_lsa_source_data but no HUD report permission' do
      let(:permissions) { { can_download_lsa_source_data: true } }

      it 'redirects and sends no export content' do
        get download_source_data_hud_reports_lsa_path(report)

        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include('zip-data')
      end
    end

    context 'without can_download_lsa_source_data' do
      it 'redirects and sends no export content' do
        get download_source_data_hud_reports_lsa_path(report)

        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include('zip-data')
      end

      # can_export_hmis_data governs the shared HMIS Exports page, not this one.
      context 'even holding can_export_hmis_data' do
        let(:permissions) { { can_view_own_hud_reports: true, can_export_hmis_data: true } }

        it 'redirects' do
          get download_source_data_hud_reports_lsa_path(report)

          expect(response).to have_http_status(:redirect)
          expect(response.body).not_to include('zip-data')
        end
      end

      # The permission check precedes set_report, so the response cannot be used to
      # tell an existing report id from a missing one.
      it "redirects rather than 404s on another user's report" do
        theirs = create_lsa_report(owner: other_user)

        get download_source_data_hud_reports_lsa_path(theirs)

        expect(response).to have_http_status(:redirect)
      end

      it 'redirects on the HIC route as well' do
        hic = create_lsa_report
        hic.update!(options: hic.options.merge('lsa_scope' => HudLsa::Fy2026::Report.available_lsa_scopes['HIC']))

        get download_source_data_hud_reports_lsa_hic_path(hic)

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'the Source HMIS Data link on the LSA report page' do
    let!(:report) { create_lsa_report }

    context 'with can_download_lsa_source_data' do
      let(:permissions) { { can_view_own_hud_reports: true, can_download_lsa_source_data: true } }

      it 'points at the LSA download action' do
        get hud_reports_lsa_path(report)

        expect(response.body).to include("href=\"#{download_source_data_hud_reports_lsa_path(report)}\"")
      end

      # A revert of the repoint would put the shared exports controller back in play.
      it 'no longer links to the shared HMIS exports page' do
        get hud_reports_lsa_path(report)

        expect(response.body).not_to include('warehouse_reports/hmis_exports/')
      end

      it 'is absent when the report has no export' do
        no_export = create_lsa_report(export_record: nil)

        get hud_reports_lsa_path(no_export)

        expect(response.body).not_to include("href=\"#{download_source_data_hud_reports_lsa_path(no_export)}\"")
      end
    end

    context 'without can_download_lsa_source_data' do
      it 'is not offered' do
        get hud_reports_lsa_path(report)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("href=\"#{download_source_data_hud_reports_lsa_path(report)}\"")
      end
    end
  end
end
