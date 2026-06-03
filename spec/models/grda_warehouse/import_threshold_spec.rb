###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ImportThreshold, type: :model do
  describe '#send_status_notifications' do
    let(:data_source) { create(:grda_warehouse_data_source) }
    let(:import_threshold) { create(:grda_warehouse_import_threshold, data_source: data_source) }
    let(:user) { create(:user, active: true) }
    let(:import_log_id) { 999 }

    before do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries.clear
      allow(import_threshold).to receive(:error_count_notification_user_ids).and_return([user.id])
      allow(import_threshold).to receive(:record_change_count_notification_user_ids).and_return([])
    end

    it 'creates a ThresholdNotificationLog before sending' do
      expect do
        import_threshold.send_status_notifications(
          import_log_id: import_log_id,
          error_threshold_met: true,
          record_count_threshold_met: false,
          paused: false,
        )
      end.to change(GrdaWarehouse::Monitoring::ThresholdNotificationLog, :count).by(1)
    end

    it 'stores import_processing email_type' do
      import_threshold.send_status_notifications(
        import_log_id: import_log_id,
        error_threshold_met: true,
        record_count_threshold_met: false,
        paused: false,
      )
      log = GrdaWarehouse::Monitoring::ThresholdNotificationLog.last
      expect(log.email_type).to eq('import_processing')
      expect(log.details['error_threshold_met']).to be true
      expect(log.details['data_source_name']).to eq(data_source.name)
    end
  end
end
