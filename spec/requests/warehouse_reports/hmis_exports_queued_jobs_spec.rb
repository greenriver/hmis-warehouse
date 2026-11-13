###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS export queued jobs', type: :request do
  include AccessControlSetup

  let(:collection) { create(:collection) }
  let(:report) { create :hmis_export_report }
  let(:hashed_report) { create(:hmis_export_report, url: 'warehouse_reports/hashed_only_hmis_exports', name: 'HUD HMIS CSV Exports (Hashed Only)') }
  let(:export_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true) }
  let(:all_reports_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true, can_view_all_reports: true) }
  # Distinct start dates identify each queued row in the response body.
  let(:own_start_date) { Date.new(2021, 2, 3) }
  let(:others_start_date) { Date.new(2020, 4, 5) }
  let(:unhashed_start_date) { Date.new(2019, 6, 7) }

  # The test environment uses the :test adapter; queue real Delayed::Job rows for the controller to read.
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :delayed_job
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before do
    Rails.cache.clear
    collection.set_viewables({ reports: [report.id, hashed_report.id] })
  end

  describe 'HMIS CSV exports page' do
    before do
      queue_export(export_user, start_date: own_start_date)
      queue_export(all_reports_user, start_date: others_start_date)
    end

    it 'lists a queued export for a user with no finished exports' do
      sign_in(export_user)
      get warehouse_reports_hmis_exports_path

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(own_start_date.to_s)
    end

    it 'lists a queued export when the page polls for running exports' do
      sign_in(export_user)
      get running_warehouse_reports_hmis_exports_path, xhr: true

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(own_start_date.to_s)
    end

    it "lists only the user's own queued export" do
      sign_in(export_user)
      get warehouse_reports_hmis_exports_path

      expect(response.body).to include(own_start_date.to_s)
      expect(response.body).not_to include(others_start_date.to_s)
    end

    it 'lists every queued export for a user who can view all reports' do
      sign_in(all_reports_user)
      get warehouse_reports_hmis_exports_path

      expect(queued_row_count).to eq(2)
      expect(response.body).to include(own_start_date.to_s, others_start_date.to_s)
    end

    it 'lists queued and finished exports together' do
      finished_export = create(:grda_warehouse_hmis_export, user_id: export_user.id, completed_at: Time.current, options: {})
      sign_in(export_user)
      get warehouse_reports_hmis_exports_path

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(warehouse_reports_hmis_export_path(finished_export))
    end

    it 'omits queued exports after the first page of finished exports' do
      create_list(:grda_warehouse_hmis_export, Pagy::DEFAULT[:items], user_id: export_user.id, completed_at: Time.current, options: {})
      oldest_export = create(:grda_warehouse_hmis_export, user_id: export_user.id, created_at: 1.day.ago, completed_at: 1.day.ago, options: {})
      sign_in(export_user)
      get warehouse_reports_hmis_exports_path(page: 2)

      expect(response.body).to include(warehouse_reports_hmis_export_path(oldest_export))
      expect(queued_row_count).to eq(0)
    end
  end

  describe 'hashed-only HMIS CSV exports page' do
    before do
      queue_export(export_user, start_date: own_start_date, hash_status: 4)
      queue_export(export_user, start_date: unhashed_start_date, hash_status: 1)
      queue_export(all_reports_user, start_date: others_start_date, hash_status: 4)
    end

    it 'lists a queued hashed export for a user with no finished exports' do
      sign_in(export_user)
      get warehouse_reports_hashed_only_hmis_exports_path

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(own_start_date.to_s)
    end

    it 'lists a queued hashed export when the page polls for running exports' do
      sign_in(export_user)
      get running_warehouse_reports_hashed_only_hmis_exports_path, xhr: true

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(own_start_date.to_s)
    end

    it 'omits queued unhashed exports' do
      sign_in(export_user)
      get warehouse_reports_hashed_only_hmis_exports_path

      expect(response.body).to include(own_start_date.to_s)
      expect(response.body).not_to include(unhashed_start_date.to_s)
    end

    it "omits another user's queued hashed export" do
      sign_in(export_user)
      get warehouse_reports_hashed_only_hmis_exports_path

      expect(response.body).to include(own_start_date.to_s)
      expect(response.body).not_to include(others_start_date.to_s)
    end

    it 'lists every queued hashed export for a user who can view all reports' do
      sign_in(all_reports_user)
      get warehouse_reports_hashed_only_hmis_exports_path

      expect(queued_row_count).to eq(2)
      expect(response.body).to include(own_start_date.to_s, others_start_date.to_s)
      expect(response.body).not_to include(unhashed_start_date.to_s)
    end

    it 'lists queued and finished hashed exports together' do
      finished_export = create(:grda_warehouse_hmis_export, user_id: export_user.id, hash_status: 4, completed_at: Time.current, options: {})
      sign_in(export_user)
      get warehouse_reports_hashed_only_hmis_exports_path

      expect(queued_row_count).to eq(1)
      expect(response.body).to include(warehouse_reports_hashed_only_hmis_export_path(finished_export))
    end
  end

  def user_with_role(**permissions)
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: "role #{permissions.inspect}", **permissions), collection)
    user
  end

  def queue_export(user, start_date:, hash_status: 1)
    Filters::HmisExport.new(user_id: user.id, start_date: start_date, end_date: Date.current, hash_status: hash_status).schedule_job(report_url: nil)
  end

  def queued_row_count
    response.body.scan('jIncompleteReport').size
  end
end
