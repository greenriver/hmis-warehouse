###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundRender::AccessLogsUserSummaryJob do
  include Rails.application.routes.url_helpers

  let(:requesting_user) { create(:user, created_at: 1.year.ago) }
  let(:filters) { { start: 5.days.ago.to_date, end: Date.current }.to_json }

  def render
    Nokogiri::HTML5.fragment(described_class.new.render_html(filters: filters, user_id: requesting_user.id))
  end

  def warehouse_visit(user, visited_at)
    ActivityLog.create!(user: user, path: '/clients', controller_name: 'clients', action_name: 'index', ip_address: '127.0.0.1', created_at: visited_at)
  end

  it 'lists a warehouse user with a link to their admin page and their first and last access' do
    visitor = create(:user, first_name: 'Jane', last_name: 'Doe', created_at: 1.year.ago)
    warehouse_visit(visitor, 2.days.ago.noon)
    warehouse_visit(visitor, 1.day.ago.noon)

    html = render
    row = html.at_css('#user-summary-warehouse-access tbody tr')

    expect(row.at_css('a')['href']).to eq(edit_admin_user_path(visitor))
    expect(row.css('td').map { |td| td.text.strip }).to eq([visitor.name_with_email, 2.days.ago.noon.to_fs(:db), 1.day.ago.noon.to_fs(:db)])
    expect(html.at_css('[data-summary-count="warehouse-access"]').text.strip).to eq('1')
  end

  it 'labels a deleted user by id instead of dropping their access row' do
    visitor = create(:user, created_at: 1.year.ago)
    warehouse_visit(visitor, 1.day.ago.noon)
    visitor.destroy!

    row = render.at_css('#user-summary-warehouse-access tbody tr')

    expect(row.at_css('td').text.strip).to eq("User ##{visitor.id} (deleted)")
  end

  it 'omits every HMIS section when the HMIS is disabled' do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)
    create(:hmis_activity_log, created_at: 1.day.ago)

    html = render

    expect(html.at_css('#user-summary-hmis-access')).to be_nil
    expect(html.at_css('[data-summary-count="hmis-access"]')).to be_nil
    expect(html.at_css('[data-summary-count="hmis-created"]')).to be_nil
  end

  it 'renders HMIS sections when the HMIS is enabled' do
    hmis_user = create(:hmis_user, created_at: 1.year.ago)
    create(:hmis_activity_log, user: hmis_user, created_at: 1.day.ago)

    html = render

    expect(html.at_css('[data-summary-count="hmis-access"]').text.strip).to eq('1')
    expect(html.at_css('#user-summary-hmis-access tbody tr td').text.strip).to eq(hmis_user.name_with_email)
  end

  it 'shows a created user with which access they hold' do
    newbie = create(:user, first_name: 'New', last_name: 'Person', created_at: 2.days.ago)
    create(:hmis_access_control, with_users: [newbie])

    row = render.at_css('#user-summary-created tbody tr')

    expect(row.css('td').map { |td| td.text.strip }).to eq([newbie.name_with_email, newbie.created_at.to_date.to_fs, 'No', 'Yes'])
    expect(render.at_css('[data-summary-count="hmis-created"]').text.strip).to eq('1')
  end

  it 'omits every CAS section when the CAS database is absent' do
    html = render

    expect(html.at_css('#user-summary-cas-access')).to be_nil
    expect(html.at_css('[data-summary-count="cas-access"]')).to be_nil
    expect(html.at_css('#user-summary-cas-created')).to be_nil
  end

  context 'when the CAS is enabled' do
    let(:visited_at) { 1.day.ago.noon }

    before do
      allow(GrdaWarehouse::Config).to receive(:cas_enabled?).and_return(true)
      access_scope = double('cas activity scope', klass: double('cas activity model', arel_table: Arel::Table.new(:activity_logs)))
      allow(access_scope).to receive(:group).and_return(access_scope)
      allow(access_scope).to receive(:pluck).and_return([[42, visited_at, visited_at]])
      allow(CasAccess::ActivityLog).to receive(:created_in_range).and_return(access_scope)
      created_scope = double('cas user scope')
      allow(created_scope).to receive(:order).and_return(created_scope)
      allow(created_scope).to receive(:pluck).and_return([[42, visited_at]])
      allow(CasAccess::User).to receive(:created_in_range).and_return(created_scope)
      allow(CasAccess::User).to receive(:name_with_email_by_id).with([42]).and_return(42 => 'Cas Person <cas@example.com>')
    end

    it 'lists CAS users by name without linking them to a warehouse user' do
      html = render
      row = html.at_css('#user-summary-cas-access tbody tr')

      expect(row.at_css('a')).to be_nil
      expect(row.css('td').map { |td| td.text.strip }).to eq(['Cas Person <cas@example.com>', visited_at.to_fs(:db), visited_at.to_fs(:db)])
      expect(html.at_css('[data-summary-count="cas-access"]').text.strip).to eq('1')
      expect(html.at_css('#user-summary-cas-created tbody tr td').text.strip).to eq('Cas Person <cas@example.com>')
      expect(html.at_css('[data-summary-count="cas-created"]').text.strip).to eq('1')
    end
  end
end
