# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::Tasks::CsvImportMonitorCollector do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:importer_log) do
    create(
      :hmis_csv_importer_log,
      data_source: data_source,
      status: 'complete',
      summary: {
        'Client.csv' => { 'pre_processed' => 1100, 'added' => 100, 'removed' => 0 },
      },
    )
  end

  before do
    GrdaWarehouse::Monitoring::MetricDefinition.maintain_csv_metrics!
  end

  describe '.run!' do
    context 'when no active monitors' do
      it 'returns without creating snapshots' do
        expect do
          described_class.run!(
            data_source: data_source,
            importer_log: importer_log,
          )
        end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end

    context 'when active monitor exists' do
      let!(:monitor) do
        create(
          :grda_warehouse_import_csv_monitor,
          data_source: data_source,
          csv_file_name: 'Client.csv',
          count_increase_threshold: 50,
          count_decrease_threshold: 50,
        )
      end

      it 'creates a MetricSnapshot for first run' do
        expect do
          described_class.run!(
            data_source: data_source,
            importer_log: importer_log,
          )
        end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

        snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.last
        expect(snapshot.entity).to eq(data_source)
        expect(snapshot.current_value).to eq(1100)
      end

      it 'updates existing snapshot on subsequent run' do
        metric_def = GrdaWarehouse::Monitoring::MetricDefinition.find_by(
          entity_type: 'GrdaWarehouse::DataSource',
          subtype: 'Client.csv',
        )
        GrdaWarehouse::Monitoring::MetricSnapshot.create!(
          entity: data_source,
          metric_definition: metric_def,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 1000,
          current_value: 1000,
          calculation_version: '1.0.0',
        )

        importer_log.summary['Client.csv']['pre_processed'] = 1050
        importer_log.save!

        expect do
          described_class.run!(
            data_source: data_source,
            importer_log: importer_log,
          )
        end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

        snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.last
        expect(snapshot.current_value).to eq(1050)
      end

      it 'sends notification when threshold exceeded' do
        metric_def = GrdaWarehouse::Monitoring::MetricDefinition.find_by(
          entity_type: 'GrdaWarehouse::DataSource',
          subtype: 'Client.csv',
        )
        GrdaWarehouse::Monitoring::MetricSnapshot.create!(
          entity: data_source,
          metric_definition: metric_def,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 1000,
          current_value: 1000,
          calculation_version: '1.0.0',
        )

        user = create(:user)
        create(
          :notification_configuration_import_threshold,
          :csv_import_notification_event,
          source: monitor,
          user: user,
          active: true,
        )

        expect do
          described_class.run!(
            data_source: data_source,
            importer_log: importer_log,
          )
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
      end

      context 'with min_additions_threshold monitor' do
        let!(:monitor) do
          create(
            :grda_warehouse_import_csv_monitor,
            data_source: data_source,
            csv_file_name: 'Client.csv',
            min_additions_threshold: 150,
            count_increase_threshold: nil,
            count_decrease_threshold: nil,
          )
        end

        it 'sends notification when added is below threshold' do
          importer_log.summary['Client.csv']['added'] = 100
          importer_log.summary['Client.csv']['pre_processed'] = 1100
          importer_log.save!

          user = create(:user)
          create(
            :notification_configuration_import_threshold,
            :csv_import_notification_event,
            source: monitor,
            user: user,
            active: true,
          )

          expect do
            described_class.run!(
              data_source: data_source,
              importer_log: importer_log,
            )
          end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
        end
      end

      context 'with max_removals_threshold monitor' do
        let!(:monitor) do
          create(
            :grda_warehouse_import_csv_monitor,
            data_source: data_source,
            csv_file_name: 'Client.csv',
            max_removals_threshold: 50,
            count_increase_threshold: nil,
            count_decrease_threshold: nil,
          )
        end

        it 'sends notification when removed exceeds threshold' do
          importer_log.summary['Client.csv']['added'] = 0
          importer_log.summary['Client.csv']['removed'] = 75
          importer_log.summary['Client.csv']['pre_processed'] = 925
          importer_log.save!

          user = create(:user)
          create(
            :notification_configuration_import_threshold,
            :csv_import_notification_event,
            source: monitor,
            user: user,
            active: true,
          )

          expect do
            described_class.run!(
              data_source: data_source,
              importer_log: importer_log,
            )
          end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
        end
      end
    end
  end
end
