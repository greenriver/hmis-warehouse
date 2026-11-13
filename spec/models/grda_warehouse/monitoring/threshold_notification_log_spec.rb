###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::ThresholdNotificationLog, type: :model do
  describe 'validations' do
    it 'requires user_id' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, user_id: nil)
      expect(log).not_to be_valid
    end

    it 'requires email_type' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, email_type: nil)
      expect(log).not_to be_valid
    end

    it 'requires sent_at' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, sent_at: nil)
      expect(log).not_to be_valid
    end

    it 'accepts valid email_type values' do
      ['metric_threshold_crossed', 'import_processing'].each do |type|
        log = create(:grda_warehouse_monitoring_threshold_notification_log, email_type: type)
        expect(log).to be_valid, "expected #{type} to be valid"
      end
    end

    it 'rejects invalid email_type values' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, email_type: 'unknown_type')
      expect(log).not_to be_valid
    end
  end

  describe 'scopes' do
    it '.for_user returns logs for the given user_id' do
      user = create(:user)
      other_user = create(:user)
      log = create(:grda_warehouse_monitoring_threshold_notification_log, user_id: user.id)
      create(:grda_warehouse_monitoring_threshold_notification_log, user_id: other_user.id)
      expect(described_class.for_user(user.id)).to contain_exactly(log)
    end

    it '.successfully_delivered excludes logs marked delivery_failed' do
      delivered = create(:grda_warehouse_monitoring_threshold_notification_log, delivery_failed: false)
      create(:grda_warehouse_monitoring_threshold_notification_log, delivery_failed: true)
      expect(described_class.successfully_delivered).to contain_exactly(delivered)
    end

    it '.metric_threshold returns only metric_threshold_crossed logs' do
      metric = create(:grda_warehouse_monitoring_threshold_notification_log, email_type: 'metric_threshold_crossed')
      create(:grda_warehouse_monitoring_threshold_notification_log, email_type: 'import_processing')
      expect(described_class.metric_threshold).to contain_exactly(metric)
    end

    it '.sent_on returns only logs sent on the given date' do
      today_log = create(:grda_warehouse_monitoring_threshold_notification_log, sent_at: Time.current)
      create(:grda_warehouse_monitoring_threshold_notification_log, sent_at: 1.day.ago)
      expect(described_class.sent_on(Date.current)).to contain_exactly(today_log)
    end
  end

  describe '.notified_metric_ids_for' do
    let(:user) { create(:user) }

    def log_with_metrics(metric_ids, **attrs)
      create(
        :grda_warehouse_monitoring_threshold_notification_log,
        {
          user_id: user.id,
          email_type: 'metric_threshold_crossed',
          sent_at: Time.current,
          delivery_failed: false,
          details: { 'crossings' => metric_ids.map { |id| { 'metric_id' => id } } },
        }.merge(attrs),
      )
    end

    it 'returns the delivered metric_ids for the user on the date as a Set of Integers' do
      log_with_metrics([11, 22])
      result = described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)
      expect(result).to be_a(Set)
      expect(result).to contain_exactly(11, 22)
    end

    it 'excludes logs marked delivery_failed' do
      log_with_metrics([11], delivery_failed: true)
      expect(described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)).to be_empty
    end

    it 'excludes logs belonging to a different user' do
      other_user = create(:user)
      log_with_metrics([11], user_id: other_user.id)
      expect(described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)).to be_empty
    end

    it 'excludes logs sent on a different day' do
      log_with_metrics([11], sent_at: 1.day.ago)
      expect(described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)).to be_empty
    end

    it 'excludes import_processing logs for the same user and date' do
      log_with_metrics([11], email_type: 'import_processing')
      expect(described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)).to be_empty
    end

    it 'collapses a metric_id repeated across crossing entries into a single value' do
      log_with_metrics([11, 11, 22])
      expect(described_class.notified_metric_ids_for(user_id: user.id, date: Date.current)).to contain_exactly(11, 22)
    end
  end

  describe '#metric_threshold_crossed?' do
    it 'returns true for metric_threshold_crossed type' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, email_type: 'metric_threshold_crossed')
      expect(log.metric_threshold_crossed?).to be true
    end
  end

  describe '#import_processing?' do
    it 'returns true for import_processing type' do
      log = build(:grda_warehouse_monitoring_threshold_notification_log, email_type: 'import_processing')
      expect(log.import_processing?).to be true
    end
  end
end
