###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Monitoring::HistoricalNotificationParser do
  describe '.parse' do
    context 'with a metric_threshold_crossed message' do
      let(:html_body) do
        <<~HTML
          <html><body>
          <h2>Threshold Monitoring Thresholds Crossed</h2>
          <p>The following items have crossed metric thresholds on May 13, 2026</p>
          <h3>Days Homeless Threshold</h3>
          <p>3 clients crossed the threshold for this metric.
            <a href="https://warehouse.example.com/admin/metric_definitions/5">View metric details</a>
          </p>
          <h3>CSV Row Count</h3>
          <p>1 data source crossed the threshold for this metric.
            <a href="https://warehouse.example.com/admin/metric_definitions/12">View metric details</a>
          </p>
          </body></html>
        HTML
      end
      let(:message) do
        build(
          :message,
          subject: 'Metric Threshold Monitoring Alert',
          body: html_body,
          html: true,
        )
      end

      it 'returns a crossings array' do
        result = described_class.parse(message)
        expect(result['crossings']).to be_an(Array)
        expect(result['crossings'].length).to eq(2)
      end

      it 'extracts metric_id from the detail URL' do
        result = described_class.parse(message)
        expect(result['crossings'].map { |c| c['metric_id'] }).to contain_exactly(5, 12)
      end

      it 'extracts metric_name from h3 text' do
        result = described_class.parse(message)
        names = result['crossings'].map { |c| c['metric_name'] }
        expect(names).to include('Days Homeless Threshold', 'CSV Row Count')
      end

      it 'sets config_url to the path portion of the metric definition link' do
        result = described_class.parse(message)
        urls = result['crossings'].map { |c| c['config_url'] }
        expect(urls).to include('/admin/metric_definitions/5', '/admin/metric_definitions/12')
      end
    end

    context 'with an import_processing message' do
      let(:html_body) do
        <<~HTML
          <html><body>
          <p>An import in the My Data Source data source has triggered notifications for the following reason(s):</p>
          <ul>
            <li>The import is paused</li>
            <li>The import crossed the configured error count threshold</li>
          </ul>
          <p>View import:<br /><a href="https://warehouse.example.com/imports/42">https://warehouse.example.com/imports/42</a></p>
          </body></html>
        HTML
      end
      let(:message) do
        build(
          :message,
          subject: 'HMIS Import Status Update',
          body: html_body,
          html: true,
        )
      end

      it 'extracts data_source_name' do
        result = described_class.parse(message)
        expect(result['data_source_name']).to eq('My Data Source')
      end

      it 'extracts paused flag' do
        result = described_class.parse(message)
        expect(result['paused']).to be true
      end

      it 'extracts error_threshold_met flag' do
        result = described_class.parse(message)
        expect(result['error_threshold_met']).to be true
      end

      it 'sets count_threshold_met false when not in email' do
        result = described_class.parse(message)
        expect(result['count_threshold_met']).to be false
      end

      it 'extracts import_log_id from import URL' do
        result = described_class.parse(message)
        expect(result['import_log_id']).to eq(42)
      end

      it 'sets config_url to the import path' do
        result = described_class.parse(message)
        expect(result['config_url']).to eq('/imports/42')
      end
    end

    context 'with a non-HTML message' do
      let(:message) { build(:message, body: 'plain text', html: false) }

      it 'returns empty hash' do
        expect(described_class.parse(message)).to eq({})
      end
    end

    context 'with unparseable HTML' do
      let(:message) { build(:message, subject: 'Metric Threshold Monitoring Alert', body: '<html><body>no structure</body></html>', html: true) }

      it 'returns empty crossings array rather than raising' do
        result = described_class.parse(message)
        expect(result['crossings']).to eq([])
      end
    end

    context 'with a prefixed subject like [TRAINING]' do
      let(:message) do
        build(
          :message,
          subject: '[TRAINING] Metric Threshold Monitoring Alert',
          body: <<~HTML,
            <html><body>
            <h3>Days Homeless Threshold</h3>
            <p><a href="https://warehouse.example.com/admin/metric_definitions/5">View metric details</a></p>
            </body></html>
          HTML
          html: true,
        )
      end

      it 'parses correctly despite the prefix' do
        result = described_class.parse(message)
        expect(result['crossings']).to be_an(Array)
        expect(result['crossings'].first['metric_id']).to eq(5)
      end
    end
  end
end
