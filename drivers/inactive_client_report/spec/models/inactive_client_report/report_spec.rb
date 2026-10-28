###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InactiveClientReport::Report, type: :model do
  include_context 'inactive client report fixtures'

  let!(:alpha) { create_report_client(first_name: 'Alpha', last_name: 'Aardvark') }

  it 'returns no activity rows when client_ids is an empty page' do
    report = described_class.new(report_filter)
    report.client_ids = []

    expect(report.activities[:entries]).to eq({})
  end

  it 'returns the entry date for every report client when client_ids is unset' do
    report = described_class.new(report_filter)

    expect(report.activities[:entries]).to eq({ alpha.id => entry_date })
  end

  describe 'most-recent service and current living situation dates' do
    let!(:beta) { create_report_client(first_name: 'Beta', last_name: 'Badger') }
    let(:alpha_service_date) { 10.days.ago.to_date }
    let(:beta_service_date) { 20.days.ago.to_date }
    let(:alpha_cls_date) { 30.days.ago.to_date }
    let(:beta_cls_date) { 40.days.ago.to_date }

    before do
      create_enrollment_record(:hud_service, alpha, DateProvided: alpha_service_date)
      create_enrollment_record(:hud_service, alpha, DateProvided: alpha_service_date - 5.days)
      create_enrollment_record(:hud_service, beta, DateProvided: beta_service_date)
      create_enrollment_record(:hud_current_living_situation, alpha, InformationDate: alpha_cls_date)
      create_enrollment_record(:hud_current_living_situation, beta, InformationDate: beta_cls_date)
    end

    it 'keeps each client on its own dates when clients fall in different batches' do
      stub_const('InactiveClientReport::Report::BATCH_SIZE', 1)
      report = described_class.new(report_filter)

      expect(report.activities[:bed_nights]).to eq({ alpha.id => alpha_service_date, beta.id => beta_service_date })
      expect(report.activities[:cls]).to eq({ alpha.id => alpha_cls_date, beta.id => beta_cls_date })
    end

    it 'limits each batch query to the PersonalIDs of the clients in that batch' do
      stub_const('InactiveClientReport::Report::BATCH_SIZE', 1)
      report = described_class.new(report_filter)
      hinted_ids = []
      callback = ->(*, payload) do
        next unless payload[:sql].include?('MAX("Services"."DateProvided")')

        # A single-value hint is sent as a bind (`= $n`); a multi-value hint as an inline IN list.
        bind_index = payload[:sql][/"Services"\."PersonalID" = \$(\d+)/, 1]
        binds = payload[:type_casted_binds]
        binds = binds.call if binds.respond_to?(:call)
        hinted_ids << (bind_index ? binds[bind_index.to_i - 1] : payload[:sql][/"Services"\."PersonalID" IN \([^)]*\)/])
      end
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { report.activities }

      expect(hinted_ids).to contain_exactly(alpha.source_clients.first.PersonalID, beta.source_clients.first.PersonalID)
    end

    it 'ignores a later service from another data source that shares the PersonalID' do
      other_ds = create(:grda_warehouse_data_source, source_type: :sftp)
      other_project = create(:hud_project, data_source: other_ds, ProjectType: 1)
      outsider = create_report_client(
        first_name: 'Other',
        last_name: 'Outsider',
        data_source: other_ds,
        enrollment_project: other_project,
        personal_id: alpha.source_clients.first.PersonalID,
      )
      create_enrollment_record(:hud_service, outsider, DateProvided: Date.yesterday)
      report = described_class.new(report_filter)

      expect(report.activities[:bed_nights]).to eq({ alpha.id => alpha_service_date, beta.id => beta_service_date })
    end
  end

  describe 'with the days-since-contact filter on' do
    let!(:beta) { create_report_client(first_name: 'Beta', last_name: 'Badger') }
    let(:filter) { report_filter(days_since_contact_min: 0, days_since_contact_max: 10_000) }

    before do
      # The days-since-contact filter keeps only clients with an assessment, a service, and a CLS.
      [alpha, beta].each do |client|
        create_enrollment_record(:hud_assessment, client, AssessmentDate: 10.days.ago.to_date)
        create_enrollment_record(:hud_service, client, DateProvided: 10.days.ago.to_date)
        create_enrollment_record(:hud_current_living_situation, client, InformationDate: 10.days.ago.to_date)
      end
    end

    it 'plucks the destination-client hint once across count, page, and activity queries' do
      report = described_class.new(filter)
      hint_plucks = []
      table = GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name
      callback = ->(*, payload) { hint_plucks << payload[:sql] if payload[:sql].start_with?("SELECT #{table}.\"client_id\" FROM #{table}") }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        report.total_client_count
        report.clients.order(:last_name).to_a
        report.activities
      end

      expect(report.total_client_count).to eq(2)
      expect(hint_plucks.size).to eq(1)
    end

    it 'returns no clients without building the days-since-contact query when no enrollment is ongoing' do
      GrdaWarehouse::ServiceHistoryEnrollment.update_all(last_date_in_program: on_date - 1.day)
      report = described_class.new(filter)

      expect(report.report_scope.to_sql).not_to include('assessment_dates')
      expect(report.clients.to_a).to eq([])
    end
  end
end
