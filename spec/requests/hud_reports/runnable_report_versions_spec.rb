###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Queueing HUD report versions', type: :request, exclude_fixpoints: true do
  before(:all) { GrdaWarehouse::Utility.clear! }
  after(:all) { GrdaWarehouse::Utility.clear! }

  let(:refusal) { 'This report version can no longer be run.' }
  let(:coc_code) { 'XX-500' }
  let(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:project) { create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 4) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:user) { create(:acl_user) }

  def active_slug(controller_class)
    controller_class.new.available_report_versions.values.find { |version| version[:active] }.fetch(:slug)
  end

  def filter_params(version)
    {
      start: '2025-10-01',
      end: '2026-09-30',
      coc_codes: [coc_code],
      report_version: version.to_s,
      project_ids: [project.id],
    }
  end

  around do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter
  end

  before do
    create(:config)
    create(:hud_project_coc, data_source_id: data_source.id, ProjectID: project.ProjectID, CoCCode: coc_code)
    collection = create(:collection)
    collection.set_viewables(projects: [project.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'APR create' do
    before { grant_hud_report(user, 'hud_reports/aprs', role: role) }

    it 'queues the current version' do
      expect do
        post hud_reports_aprs_path, params: { filter: filter_params(active_slug(HudApr::AprsController)) }
      end.to change(HudReports::ReportInstance, :count).by(1)

      expect(Reporting::Hud::RunReportJob).to have_been_enqueued
    end

    it 'refuses an old version without creating or queueing a run' do
      expect do
        post hud_reports_aprs_path, params: { filter: filter_params(:fy2023) }
      end.not_to change(HudReports::ReportInstance, :count)

      expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued
      expect(response).to redirect_to(history_hud_reports_aprs_path)
      expect(flash[:alert]).to eq(refusal)
    end

    it 'refuses a version no generator serves' do
      expect do
        post hud_reports_aprs_path, params: { filter: filter_params(:fy1999) }
      end.not_to change(HudReports::ReportInstance, :count)

      expect(flash[:alert]).to eq(refusal)
    end
  end

  describe 'single question create' do
    before { grant_hud_report(user, 'hud_reports/paths', role: role) }

    it 'refuses an old version' do
      expect do
        post hud_reports_path_questions_path(path_id: 0), params: { question: 'Q8-Q16', filter: filter_params(:fy2024) }
      end.not_to change(HudReports::ReportInstance, :count)

      expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued
      expect(flash[:alert]).to eq(refusal)
    end
  end

  describe 'LSA create' do
    before { grant_hud_report(user, 'hud_reports/lsas', role: role) }

    it 'refuses an old version' do
      expect do
        post hud_reports_lsas_path, params: { filter: filter_params(:fy2026) }
      end.not_to change(HudReports::ReportInstance, :count)

      expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued
      expect(response).to redirect_to(history_hud_reports_lsas_path)
      expect(flash[:alert]).to eq(refusal)
    end
  end

  describe 'PIT create' do
    before { grant_hud_report(user, 'hud_reports/pits', role: role) }

    it 'refuses an old version' do
      expect do
        post hud_reports_pits_path, params: { filter: filter_params(:fy2024) }
      end.not_to change(HudReports::ReportInstance, :count)

      expect(Reporting::Hud::RunReportJob).not_to have_been_enqueued
      expect(flash[:alert]).to eq(refusal)
    end
  end

  describe 'new report page' do
    before { grant_hud_report(user, 'hud_reports/aprs', role: role) }

    def queue_button
      Nokogiri::HTML(response.body).at_css('[data-filter-projects-target=submitButton]')
    end

    it 'replaces the queue button with an explanation for an old version' do
      get new_hud_reports_apr_path, params: { filter: { report_version: 'fy2023' } }

      doc = Nokogiri::HTML(response.body)
      expect(doc.css('input[type=submit], button[type=submit]')).to be_empty
      expect(queue_button.text.strip).to start_with(refusal)
    end

    it 'links to a new report on the current version with the requested settings' do
      get new_hud_reports_apr_path, params: { filter: filter_params(:fy2023) }

      links = queue_button.css('a').map { |a| URI.parse(a['href']) }
      expect(links.map(&:path)).to eq([new_hud_reports_apr_path])
      filter = Rack::Utils.parse_nested_query(links.first.query).fetch('filter')
      expect(filter).to include(
        'report_version' => active_slug(HudApr::AprsController).to_s,
        'coc_codes' => [coc_code],
        'project_ids' => [project.id.to_s],
      )
      expect(filter.values_at('start', 'end').map { |date| Date.parse(date) }).to eq([Date.new(2025, 10, 1), Date.new(2026, 9, 30)])

      get links.first.to_s
      expect(queue_button['type']).to eq('submit')
    end

    it 'leaves the queue button enabled for the current version' do
      get new_hud_reports_apr_path, params: { filter: { report_version: active_slug(HudApr::AprsController).to_s } }

      expect(queue_button['type']).to eq('submit')
      expect(queue_button['disabled']).to be_nil
      expect(response.body).not_to include(refusal)
    end
  end

  describe 'available versions' do
    it 'allows at most one active version per HUD report controller' do
      Rails.application.eager_load!
      controllers = HudReports::BaseController.descendants

      expect(controllers).to include(HudPit::PitsController, HudLsa::LsasController, HudApr::AprsController)
      active_counts = controllers.to_h do |controller|
        [controller.name, controller.new.available_report_versions.values.count { |version| version[:active] }]
      end

      expect(active_counts.select { |_, count| count > 1 }).to eq({})
    end

    it 'maps each active version to a generator' do
      Rails.application.eager_load!
      missing = HudReports::BaseController.descendants.flat_map do |controller|
        instance = controller.new
        next [] unless instance.respond_to?(:possible_generator_classes, true)

        instance.available_report_versions.values.select { |version| version[:active] }.filter_map do |version|
          "#{controller.name} #{version[:slug]}" if instance.send(:possible_generator_classes)[version[:slug]].blank?
        end
      end

      expect(missing).to eq([])
    end
  end
end
