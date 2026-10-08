###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'report visibility users' do
  let(:report_attributes) { {} }
  let(:collection) { create(:collection) }
  let(:report_definition) { create(:touch_point_report, url: report_definition_url, name: 'Report visibility') }
  let(:all_reports_user) { user_with_role(can_view_all_reports: true, can_view_assigned_reports: true) }
  let(:own_reports_user) { user_with_role(can_view_assigned_reports: true, can_view_clients: true) }

  # Permission lookups are cached in Rails.cache, which outlives each example's transaction.
  before do
    Rails.cache.clear
    collection.set_viewables({ reports: [report_definition.id] })
  end

  let!(:others_report) { report_class.create!(user_id: all_reports_user.id, **report_attributes) }
  let!(:own_report) { report_class.create!(user_id: own_reports_user.id, **report_attributes) }

  # Report definitions are visible through can_view_assigned_reports, so the all-reports role needs it too.
  # setup_access_control names the user group from the role name and collection, so
  # roles sharing a name would put every user in one group with all their permissions.
  def user_with_role(**permissions)
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: "role #{permissions.keys.join(' ')}", **permissions), collection)
    user
  end
end

RSpec.shared_examples 'report member actions limited to visible reports' do |destroy: true|
  include_context 'report visibility users'

  before { sign_in(own_reports_user) }

  it 'returns not found when showing a report run by another user' do
    get report_path.call(others_report)

    expect(response).to have_http_status(:not_found)
  end

  if destroy
    it 'returns not found and keeps the record when deleting a report run by another user' do
      delete report_path.call(others_report)

      expect(response).to have_http_status(:not_found)
      expect(report_class.where(id: others_report.id)).to exist
    end

    it 'deletes a report the user ran' do
      delete report_path.call(own_report)

      expect(report_class.where(id: own_report.id)).not_to exist
    end
  end
end

RSpec.shared_examples 'a document export limited to visible reports' do
  include_context 'report visibility users'

  let(:query_key) { 'id' }

  def export_for(user, report_id)
    described_class.new(user: user, query_string: { query_key => report_id }.to_query)
  end

  it 'authorizes a report the user ran' do
    expect(export_for(own_reports_user, own_report.id).authorized?).to be(true)
  end

  it 'refuses a report run by another user' do
    expect(export_for(own_reports_user, others_report.id).authorized?).to be(false)
  end

  it 'authorizes any report for a user who can view all reports' do
    expect(export_for(all_reports_user, own_report.id).authorized?).to be(true)
  end

  it 'refuses an id with no report' do
    expect(export_for(all_reports_user, 0).authorized?).to be(false)
  end

  it 'refuses a user who can view all reports when the definition is not assigned' do
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: 'unassigned all reports', can_view_all_reports: true, can_view_assigned_reports: true), create(:collection))

    expect(export_for(user, own_report.id).authorized?).to be(false)
  end
end
