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

  describe '.backfill' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    let!(:message) do
      create(
        :message,
        user: user,
        subject: described_class::METRIC_THRESHOLD_SUBJECT,
        body: '<html><body><h3>Days Homeless</h3><p><a href="http://x.com/admin/metric_definitions/1">View metric details</a></p></body></html>',
        html: true,
      )
    end
    let!(:other_message) do
      create(
        :message,
        user: other_user,
        subject: described_class::IMPORT_PROCESSING_SUBJECT,
        body: 'plain text',
        html: false,
      )
    end

    it 'creates stub logs for all users with threshold messages' do
      expect do
        described_class.backfill
      end.to change { described_class.where(message_id: [message.id, other_message.id]).count }.by(2)
    end

    it 'links each stub log to its message' do
      described_class.backfill
      expect(described_class.where(message_id: [message.id, other_message.id]).pluck(:message_id)).to contain_exactly(message.id, other_message.id)
    end

    it 'does not create duplicate stubs on second call' do
      described_class.backfill
      expect do
        described_class.backfill
      end.not_to change(described_class, :count)
    end

    it 'sets email_type from the message subject' do
      described_class.backfill
      log = described_class.find_by!(message_id: message.id)
      expect(log.email_type).to eq('metric_threshold_crossed')
    end

    context 'with a prefixed subject like [TRAINING]' do
      let!(:prefixed_message) do
        create(
          :message,
          user: user,
          subject: "[TRAINING] #{described_class::METRIC_THRESHOLD_SUBJECT}",
          body: 'plain text',
          html: false,
        )
      end

      it 'picks up messages with prefixed subjects' do
        expect do
          described_class.backfill
        end.to change { described_class.where(message_id: [message.id, other_message.id, prefixed_message.id]).count }.by(3)
      end

      it 'sets email_type correctly for a prefixed subject' do
        described_class.backfill
        log = described_class.find_by!(message_id: prefixed_message.id)
        expect(log.email_type).to eq('metric_threshold_crossed')
      end
    end
  end
end
