###
# Copyright Green River Data Group, Inc.
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

  context 'when crossing has previous_value of zero' do
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
            data: [{ entity_id: data_source.id, current_value: 50, previous_value: 0 }],
            total_count: 1,
            truncated: false,
            entity_label: 'data source',
          },
        },
      )
    end

    it 'sends an email notification (previous_value of 0 is not treated as absent)' do
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(csv_user.email)
    end
  end

  context 'notification logging' do
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

    it 'creates a ThresholdNotificationLog for the recipient user' do
      expect do
        described_class.new.perform(calculation_date)
      end.to change(GrdaWarehouse::Monitoring::ThresholdNotificationLog, :count).by(1)
    end

    it 'stores the correct email_type on the log' do
      described_class.new.perform(calculation_date)
      log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.last
      expect(log.email_type).to eq('metric_threshold_crossed')
    end

    it 'stores crossings detail in the log' do
      described_class.new.perform(calculation_date)
      log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.last
      expect(log.details['crossings']).to be_an(Array)
      expect(log.details['crossings'].first['metric_id']).to eq(metric_def.id)
    end

    it 'marks log as delivery_failed when email raises' do
      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_raise(SocketError, 'connection refused')
      described_class.new.perform(calculation_date)
      log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.last
      expect(log.delivery_failed).to be true
      expect(log.delivery_error).to include('connection refused')
    end
  end

  context 'idempotency / dedup across repeated runs' do
    let(:csv_alert) { described_class::CSV_IMPORT_ALERT_CODE }
    # Non-CSV alert codes seeded by AlertDefinition.maintain! (called in the top-level before).
    let(:days_homeless_alert_code) { 'metric_days_homeless_threshold' }
    let(:household_alert_code) { 'metric_household_size_threshold' }

    # Metric A: seeded CSV metric (real record, category csv_import)
    let(:csv_metric) do
      GrdaWarehouse::Monitoring::MetricDefinition.find_by!(
        entity_type: 'GrdaWarehouse::DataSource',
        subtype: 'Client.csv',
      )
    end
    # Metrics B and C: real non-CSV metric definitions so build_notification_details records
    # their metric_id in the log (a metric with no MetricDefinition row would be skipped).
    let(:metric_b) { create(:grda_warehouse_monitoring_metric_definition) }
    let(:metric_c) { create(:grda_warehouse_monitoring_metric_definition) }

    let!(:monitor) do
      create(
        :grda_warehouse_import_csv_monitor,
        data_source: data_source,
        csv_file_name: 'Client.csv',
        count_increase_threshold: 50,
      )
    end

    def csv_snapshot_info(display_name:)
      {
        display_name: display_name,
        data: [{ entity_id: data_source.id, current_value: 1100, previous_value: 1000 }],
        total_count: 1,
        truncated: false,
        entity_label: 'data source',
      }
    end

    def non_csv_snapshot_info(display_name:)
      {
        display_name: display_name,
        data: [{ entity_id: 1, current_value: 200, previous_value: 100 }],
        total_count: 1,
        truncated: false,
        entity_label: 'client',
      }
    end

    # Mirrors the ImportCsvMonitor notification-config controller create path
    # (no reusable model method exists for this subscription).
    def subscribe_csv(user, on_monitor = monitor)
      GrdaWarehouse::NotificationConfiguration.create!(
        source: on_monitor,
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        user: user,
        active: true,
      )
    end

    def metric_ids_for(user)
      GrdaWarehouse::Monitoring::ThresholdNotificationLog.
        for_user(user.id).
        order(:id).
        last.
        crossings.
        map { |c| c['metric_id'] }
    end

    def delivery_to(user)
      ActionMailer::Base.deliveries.find { |mail| mail.to.include?(user.email) }
    end

    # Persist a real MetricSnapshot the production detection query reads.
    def persist_csv_snapshot(observation_date:, value:)
      GrdaWarehouse::Monitoring::MetricSnapshot.create!(
        metric_definition: csv_metric,
        entity: data_source,
        initial_observation_date: observation_date,
        current_observation_date: observation_date,
        initial_value: value,
        current_value: value,
        calculation_version: '1.0.0',
      )
    end

    it '(a) does not re-send on a second identical run' do
      user = create(:user, active: true)
      subscribe_csv(user)
      stub_crossings(csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') })

      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(1)

      expect do
        described_class.new.perform(calculation_date)
      end.not_to(change { ActionMailer::Base.deliveries.count })
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(1)
    end

    it '(b) sends only the newly-crossed metric on a later run' do
      user = create(:user, active: true)
      subscribe_csv(user)
      user.subscribe_to_system_alert!(days_homeless_alert_code)

      stub_crossings(csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') })
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)

      stub_crossings(
        csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') },
        'metric_days_homeless_threshold' => { metric_b.id => non_csv_snapshot_info(display_name: 'BetaMetric') },
      )
      described_class.new.perform(calculation_date)

      expect(ActionMailer::Base.deliveries.count).to eq(2)
      second = ActionMailer::Base.deliveries.last
      expect(second.body.encoded).to include('BetaMetric')
      expect(second.body.encoded).not_to include('AlphaMetric')
      expect(metric_ids_for(user)).to eq([metric_b.id])
    end

    it '(c) retries a metric whose earlier delivery failed' do
      user = create(:user, active: true)
      subscribe_csv(user)
      stub_crossings(csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') })

      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_raise(SocketError, 'connection refused')
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries).to be_empty
      first_log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.order(:id).last
      expect(first_log.delivery_failed).to be true

      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_call_original
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      new_log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.order(:id).last
      expect(new_log.id).not_to eq(first_log.id)
      expect(new_log.delivery_failed).to be false
    end

    it '(d) still notifies a user who first subscribes on a later run' do
      user1 = create(:user, active: true)
      user2 = create(:user, active: true)
      subscribe_csv(user1)
      subscribe_csv(user2)
      stub_crossings(csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') })

      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(2)

      user3 = create(:user, active: true)
      subscribe_csv(user3)
      described_class.new.perform(calculation_date)

      expect(ActionMailer::Base.deliveries.count).to eq(3)
      expect(ActionMailer::Base.deliveries.last.to).to include(user3.email)
    end

    it '(e) resends on a later day' do
      user = create(:user, active: true)
      subscribe_csv(user)
      stub_crossings(csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') })

      travel_to(Time.zone.local(2026, 7, 21, 8, 0)) do
        described_class.new.perform(calculation_date)
      end
      travel_to(Time.zone.local(2026, 7, 22, 8, 0)) do
        described_class.new.perform(calculation_date)
      end

      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(2)
    end

    it '(f) dedups per-user and per-metric across multiple users and metrics' do
      user1 = create(:user, active: true)
      user2 = create(:user, active: true)
      [user1, user2].each do |u|
        subscribe_csv(u)
        u.subscribe_to_system_alert!(days_homeless_alert_code)
      end

      a_and_b = {
        csv_alert => { csv_metric.id => csv_snapshot_info(display_name: 'AlphaMetric') },
        'metric_days_homeless_threshold' => { metric_b.id => non_csv_snapshot_info(display_name: 'BetaMetric') },
      }
      stub_crossings(a_and_b)

      # Run 1: each user gets one email covering both metrics.
      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      ActionMailer::Base.deliveries.each do |mail|
        expect(mail.body.encoded).to include('AlphaMetric')
        expect(mail.body.encoded).to include('BetaMetric')
      end
      [user1, user2].each do |u|
        expect(metric_ids_for(u)).to contain_exactly(csv_metric.id, metric_b.id)
      end

      # Run 2 (identical): full dedup, nothing new.
      expect do
        described_class.new.perform(calculation_date)
      end.not_to(change { ActionMailer::Base.deliveries.count })
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(2)

      # Run 3: add metric C for both users → each is emailed about C only.
      [user1, user2].each { |u| u.subscribe_to_system_alert!(household_alert_code) }
      stub_crossings(
        a_and_b.merge(
          'metric_household_size_threshold' => { metric_c.id => non_csv_snapshot_info(display_name: 'GammaMetric') },
        ),
      )
      described_class.new.perform(calculation_date)

      expect(ActionMailer::Base.deliveries.count).to eq(4)
      ActionMailer::Base.deliveries.last(2).each do |mail|
        expect(mail.body.encoded).to include('GammaMetric')
        expect(mail.body.encoded).not_to include('AlphaMetric')
        expect(mail.body.encoded).not_to include('BetaMetric')
      end
      [user1, user2].each do |u|
        expect(metric_ids_for(u)).to eq([metric_c.id])
      end
    end

    it "(g) aggregates each user's CSV metrics into one email without leaking across users" do
      enrollment_monitor = create(
        :grda_warehouse_import_csv_monitor,
        data_source: data_source,
        csv_file_name: 'Enrollment.csv',
        count_increase_threshold: 50,
      )
      enrollment_metric = GrdaWarehouse::Monitoring::MetricDefinition.find_by!(
        entity_type: 'GrdaWarehouse::DataSource',
        subtype: 'Enrollment.csv',
      )

      one_metric_user = create(:user, active: true)
      two_metric_user = create(:user, active: true)
      subscribe_csv(one_metric_user)                     # Client.csv only
      subscribe_csv(two_metric_user)                     # Client.csv
      subscribe_csv(two_metric_user, enrollment_monitor) # + Enrollment.csv

      stub_crossings(
        csv_alert => {
          csv_metric.id => csv_snapshot_info(display_name: 'ClientCsvMetric'),
          enrollment_metric.id => csv_snapshot_info(display_name: 'EnrollmentCsvMetric'),
        },
      )

      described_class.new.perform(calculation_date)

      # One email each, and the second CSV metric does not leak to the user not subscribed to it.
      expect(ActionMailer::Base.deliveries.count).to eq(2)

      one_metric_body = delivery_to(one_metric_user).body.encoded
      expect(one_metric_body).to include('ClientCsvMetric')
      expect(one_metric_body).not_to include('EnrollmentCsvMetric')
      expect(metric_ids_for(one_metric_user)).to contain_exactly(csv_metric.id)

      two_metric_body = delivery_to(two_metric_user).body.encoded
      expect(two_metric_body).to include('ClientCsvMetric')
      expect(two_metric_body).to include('EnrollmentCsvMetric')
      expect(metric_ids_for(two_metric_user)).to contain_exactly(csv_metric.id, enrollment_metric.id)

      # Re-run: both users fully deduped across all their CSV metrics.
      expect do
        described_class.new.perform(calculation_date)
      end.not_to(change { ActionMailer::Base.deliveries.count })
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(2)
    end

    it '(h) [integration] dedups against real crossing detection, no stub' do
      # Exercises the real MetricDefinition.threshold_crossings_for_alerts path (no stub_crossings),
      # proving the guard suppresses a genuine second run and that the detected crossing shape
      # feeds build_notification_details / the mailer correctly.
      user = create(:user, active: true)
      subscribe_csv(user)

      # A baseline snapshot plus a crossing dated on calculation_date is what the detection SQL
      # looks for (a current snapshot with initial_observation_date == calculation_date and an
      # earlier snapshot to compare against).
      persist_csv_snapshot(observation_date: calculation_date - 7.days, value: 1000)
      persist_csv_snapshot(observation_date: calculation_date, value: 1100)

      described_class.new.perform(calculation_date)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
      expect(metric_ids_for(user)).to contain_exactly(csv_metric.id)

      # Second run recomputes the identical real crossing but must not re-send.
      expect do
        described_class.new.perform(calculation_date)
      end.not_to(change { ActionMailer::Base.deliveries.count })
      expect(GrdaWarehouse::Monitoring::ThresholdNotificationLog.count).to eq(1)
    end
  end
end
