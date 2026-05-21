###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
