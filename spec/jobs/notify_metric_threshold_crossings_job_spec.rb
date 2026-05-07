###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifyMetricThresholdCrossingsJob, type: :job do
  let(:calculation_date) { Date.current }
  let(:data_source) { create(:grda_warehouse_data_source) }

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
    GrdaWarehouse::Monitoring::MetricDefinition.maintain_csv_metrics!
    GrdaWarehouse::AlertDefinition.maintain!
    # Bypass advisory lock in tests
    allow(GrdaWarehouseBase).to receive(:with_advisory_lock).and_yield
  end

  def stub_crossings(crossings_by_alert)
    scope = double('metric_definition_scope')
    allow(GrdaWarehouse::Monitoring::MetricDefinition).to receive(:active).and_return(scope)
    allow(scope).to receive(:threshold_crossings_for_alerts).and_return(crossings_by_alert)
  end

  context 'when there are no crossings' do
    before { stub_crossings({}) }

    it 'sends no emails' do
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context 'with CSV import crossings' do
    let(:metric_def) do
      GrdaWarehouse::Monitoring::MetricDefinition.find_by!(
        entity_type: 'GrdaWarehouse::DataSource',
        subtype: 'Client.csv',
      )
    end
    let(:csv_user) { create(:user, active: true) }
    let!(:monitor) do
      create(
        :grda_warehouse_import_csv_monitor,
        data_source: data_source,
        csv_file_name: 'Client.csv',
        count_increase_threshold: 50,
      )
    end

    before do
      GrdaWarehouse::NotificationConfiguration.create!(
        source: monitor,
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        user: csv_user,
        active: true,
      )
      stub_crossings(
        NotifyMetricThresholdCrossingsJob::CSV_IMPORT_ALERT_CODE => {
          metric_def.id => {
            display_name: 'Client.csv row count',
            data: [{ entity_id: data_source.id, current_value: 1100, previous_value: 1000 }],
            total_count: 1,
            truncated: false,
            entity_label: 'data source',
          },
        },
      )
    end

    it 'sends one email to the subscribed user' do
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(csv_user.email)
    end

    context 'when user is inactive' do
      let(:csv_user) { create(:user, active: false) }

      it 'sends no emails' do
        described_class.new.perform(calculation_date)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when monitor has no subscribed users' do
      before { GrdaWarehouse::NotificationConfiguration.delete_all }

      it 'sends no emails' do
        described_class.new.perform(calculation_date)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  context 'with non-CSV metric crossings' do
    let(:non_csv_metric_id) { 9999 }
    let(:alert_code) { 'metric_days_homeless_threshold' }
    let(:alert_definition) { GrdaWarehouse::AlertDefinition.find_by!(code: alert_code) }
    let(:subscribed_user) { create(:user, active: true) }
    let!(:contact) { create(:grda_warehouse_contact_user, user: subscribed_user) }

    before do
      create(:contact_alert_subscription, contact: contact, alert_definition: alert_definition, active: true)
      stub_crossings(
        alert_code => {
          non_csv_metric_id => {
            display_name: 'Days Homeless (Last 3 Years)',
            data: [{ entity_id: 1, current_value: 200, previous_value: 100 }],
            total_count: 1,
            truncated: false,
            entity_label: 'client',
          },
        },
      )
    end

    it 'sends one email to the subscribed user' do
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(subscribed_user.email)
    end
  end

  context 'when a user is subscribed to both CSV and non-CSV crossings' do
    let(:metric_def) do
      GrdaWarehouse::Monitoring::MetricDefinition.find_by!(
        entity_type: 'GrdaWarehouse::DataSource',
        subtype: 'Client.csv',
      )
    end
    let(:non_csv_metric_id) { 9999 }
    let(:alert_code) { 'metric_days_homeless_threshold' }
    let(:alert_definition) { GrdaWarehouse::AlertDefinition.find_by!(code: alert_code) }
    let(:shared_user) { create(:user, active: true) }
    let!(:monitor) do
      create(
        :grda_warehouse_import_csv_monitor,
        data_source: data_source,
        csv_file_name: 'Client.csv',
        count_increase_threshold: 50,
      )
    end
    let!(:contact) { create(:grda_warehouse_contact_user, user: shared_user) }

    before do
      # Subscribe shared_user to both CSV monitor and non-CSV alert
      GrdaWarehouse::NotificationConfiguration.create!(
        source: monitor,
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        user: shared_user,
        active: true,
      )
      create(:contact_alert_subscription, contact: contact, alert_definition: alert_definition, active: true)
      stub_crossings(
        NotifyMetricThresholdCrossingsJob::CSV_IMPORT_ALERT_CODE => {
          metric_def.id => {
            display_name: 'Client.csv row count',
            data: [{ entity_id: data_source.id, current_value: 1100, previous_value: 1000 }],
            total_count: 1,
            truncated: false,
            entity_label: 'data source',
          },
        },
        alert_code => {
          non_csv_metric_id => {
            display_name: 'Days Homeless (Last 3 Years)',
            data: [{ entity_id: 1, current_value: 200, previous_value: 100 }],
            total_count: 1,
            truncated: false,
            entity_label: 'client',
          },
        },
      )
    end

    it 'sends exactly one email to the shared user covering both crossings' do
      described_class.new.perform(calculation_date)
      emails = ActionMailer::Base.deliveries.select { |m| m.to.include?(shared_user.email) }
      expect(emails.count).to eq(1)
    end

    it 'includes both crossing types in the single email' do
      described_class.new.perform(calculation_date)
      email_body = ActionMailer::Base.deliveries.first.body.encoded
      expect(email_body).to include('Client.csv row count')
      expect(email_body).to include('Days Homeless (Last 3 Years)')
    end
  end
end
