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
  let(:export_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true) }
  let(:all_reports_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true, can_view_all_reports: true) }
  # Distinct start dates identify each user's queued row.
  let(:own_start_date) { Date.new(2021, 2, 3) }
  let(:others_start_date) { Date.new(2020, 4, 5) }

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
    collection.set_viewables({ reports: [report.id] })
    # Queued rows render inside the finished-export list, which renders only when it has a row.
    create(:grda_warehouse_hmis_export, user_id: export_user.id, completed_at: Time.current, options: {})
    queue_export(export_user, start_date: own_start_date)
    queue_export(all_reports_user, start_date: others_start_date)
  end

  it "lists only the user's own queued export" do
    sign_in(export_user)
    get warehouse_reports_hmis_exports_path

    expect(queued_row_count).to eq(1)
    expect(response.body).to include(own_start_date.to_s)
    expect(response.body).not_to include(others_start_date.to_s)
  end

  it 'lists every queued export for a user who can view all reports' do
    sign_in(all_reports_user)
    get warehouse_reports_hmis_exports_path

    expect(queued_row_count).to eq(2)
    expect(response.body).to include(own_start_date.to_s, others_start_date.to_s)
  end

  def user_with_role(**permissions)
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: "role #{permissions.inspect}", **permissions), collection)
    user
  end

  def queue_export(user, start_date:)
    Filters::HmisExport.new(user_id: user.id, start_date: start_date, end_date: Date.current).schedule_job(report_url: nil)
  end

  def queued_row_count
    response.body.scan('jIncompleteReport').size
  end
end
