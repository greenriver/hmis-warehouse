# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::DbMonitor do
  let(:config) { instance_double(GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration) }

  before do
    allow(GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration).to receive(:new).and_return(config)
    allow(config).to receive(:enabled?).and_return(false)
    allow(config).to receive(:block_threshold_pct).and_return(nil)
    allow(config).to receive(:alert_threshold_pct).and_return(nil)
    allow(config).to receive(:min_block_threshold_gb).and_return(1)
    allow(config).to receive(:max_block_threshold_gb).and_return(100)
    allow(Sentry).to receive(:capture_message)
  end

  describe '.assert_healthy!' do
    context 'when no thresholds are configured' do
      it 'returns without contacting AWS' do
        expect(Aws::RDS::Client).not_to receive(:new)
        described_class.assert_healthy!
      end
    end

    context 'when thresholds are configured' do
      let(:rds_instance) { GrdaWarehouse::DbMonitor::RdsInstance.new(id: 'my-instance', allocated_storage_gb: 100, free_storage_gb: 15.0) }

      before do
        allow(config).to receive(:enabled?).and_return(true)
        allow(config).to receive(:block_threshold_pct).and_return(10)
        allow(described_class).to receive(:resolve_instance).and_return(rds_instance)
      end

      context 'when the RDS instance cannot be resolved' do
        before { allow(described_class).to receive(:resolve_instance).and_return(nil) }

        it 'sends a Sentry warning and does not raise' do
          expect(Sentry).to receive(:capture_message).with(/could not resolve/, hash_including(level: :warning))
          expect { described_class.assert_healthy! }.not_to raise_error
        end
      end

      context 'when free storage space cannot be retrieved' do
        let(:rds_instance) { GrdaWarehouse::DbMonitor::RdsInstance.new(id: 'my-instance', allocated_storage_gb: 100, free_storage_gb: nil) }

        it 'sends a Sentry warning and does not raise' do
          expect(Sentry).to receive(:capture_message).with(/unable to retrieve/, hash_including(level: :warning))
          expect { described_class.assert_healthy! }.not_to raise_error
        end
      end

      context 'block threshold' do
        # 100 GB allocated * 10% = 10 GB computed threshold

        it 'raises Error when free space is below the threshold' do
          allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 8.0))
          expect { described_class.assert_healthy! }.to raise_error(GrdaWarehouse::DbMonitor::Error, /block threshold reached/)
        end

        it 'does not raise when free space is above the threshold' do
          expect { described_class.assert_healthy! }.not_to raise_error
        end

        context 'when the computed threshold exceeds max_block_threshold_gb' do
          # 1000 GB allocated * 10% = 100 GB, but max is 50 GB -> clamped to 50 GB
          let(:rds_instance) { GrdaWarehouse::DbMonitor::RdsInstance.new(id: 'my-instance', allocated_storage_gb: 1000, free_storage_gb: 15.0) }

          before do
            allow(config).to receive(:max_block_threshold_gb).and_return(50)
          end

          it 'does not raise when free space is above the clamped ceiling' do
            allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 60.0))
            expect { described_class.assert_healthy! }.not_to raise_error
          end

          it 'raises when free space is below the clamped ceiling' do
            allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 40.0))
            expect { described_class.assert_healthy! }.to raise_error(GrdaWarehouse::DbMonitor::Error)
          end
        end

        context 'when the computed threshold is below min_block_threshold_gb' do
          # 5 GB allocated * 10% = 0.5 GB, but min is 2 GB -> clamped to 2 GB
          let(:rds_instance) { GrdaWarehouse::DbMonitor::RdsInstance.new(id: 'my-instance', allocated_storage_gb: 5, free_storage_gb: 15.0) }

          before do
            allow(config).to receive(:min_block_threshold_gb).and_return(2)
          end

          it 'raises when free space is below the clamped floor' do
            allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 1.0))
            expect { described_class.assert_healthy! }.to raise_error(GrdaWarehouse::DbMonitor::Error)
          end

          it 'does not raise when free space is above the clamped floor' do
            allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 3.0))
            expect { described_class.assert_healthy! }.not_to raise_error
          end
        end
      end

      context 'when an AWS error occurs' do
        before do
          allow(described_class).to receive(:resolve_instance).and_raise(
            Aws::RDS::Errors::ServiceError.new(nil, 'access denied'),
          )
        end

        it 'sends a Sentry warning and does not raise' do
          expect(Sentry).to receive(:capture_message).with(/AWS error/, hash_including(level: :warning))
          expect { described_class.assert_healthy! }.not_to raise_error
        end
      end

      context 'alert threshold' do
        let(:rds_instance) { GrdaWarehouse::DbMonitor::RdsInstance.new(id: 'my-instance', allocated_storage_gb: 100, free_storage_gb: 15.0) }

        before do
          allow(config).to receive(:block_threshold_pct).and_return(nil)
          allow(config).to receive(:alert_threshold_pct).and_return(20)
        end

        it 'sends a Sentry warning when free space is below the alert threshold' do
          # 100 GB allocated * 20% = 20 GB alert threshold; 15 GB free -> alert
          expect(Sentry).to receive(:capture_message).with(
            /low on storage/,
            hash_including(level: :warning, extra: hash_including(:free_storage_gb, :alert_threshold_gb)),
          )
          described_class.assert_healthy!
        end

        it 'does not send a warning when free space is above the alert threshold' do
          allow(described_class).to receive(:resolve_instance).and_return(rds_instance.with(free_storage_gb: 25.0))
          expect(Sentry).not_to receive(:capture_message)
          described_class.assert_healthy!
        end
      end
    end
  end

  describe '.resolve_instance' do
    let(:rds_client) { instance_double(Aws::RDS::Client) }
    let(:db_instance) do
      instance_double(
        Aws::RDS::Types::DBInstance,
        endpoint: instance_double(Aws::RDS::Types::Endpoint, address: 'my-host.abc123.us-east-1.rds.amazonaws.com'),
        db_instance_identifier: 'my-instance',
        allocated_storage: 200,
      )
    end
    let(:page) { instance_double(Aws::RDS::Types::DBInstanceMessage, db_instances: [db_instance]) }

    before do
      allow(Aws::RDS::Client).to receive(:new).and_return(rds_client)
      allow(rds_client).to receive(:describe_db_instances).and_return([page])
      allow(GrdaWarehouse::DbMonitor::FreeStorageSpace).to receive(:call).and_return(42.5)
    end

    context 'when WAREHOUSE_DATABASE_HOST is not set' do
      before { stub_const('ENV', ENV.to_h.except('WAREHOUSE_DATABASE_HOST')) }

      it 'returns nil without contacting AWS' do
        expect(Aws::RDS::Client).not_to receive(:new)
        expect(described_class.resolve_instance).to be_nil
      end
    end

    context 'when WAREHOUSE_DATABASE_HOST matches an exact endpoint address' do
      before { stub_const('ENV', ENV.to_h.merge('WAREHOUSE_DATABASE_HOST' => 'my-host.abc123.us-east-1.rds.amazonaws.com')) }

      it 'returns an RdsInstance with identifier, allocated storage, and free storage' do
        result = described_class.resolve_instance
        expect(result.id).to eq('my-instance')
        expect(result.allocated_storage_gb).to eq(200)
        expect(result.free_storage_gb).to eq(42.5)
      end
    end

    context 'when no RDS instance matches the host' do
      before { stub_const('ENV', ENV.to_h.merge('WAREHOUSE_DATABASE_HOST' => 'other-host')) }

      it 'returns nil' do
        expect(described_class.resolve_instance).to be_nil
      end
    end

    context 'when an instance has no endpoint' do
      let(:db_instance) { instance_double(Aws::RDS::Types::DBInstance, endpoint: nil, db_instance_identifier: 'no-endpoint-instance', allocated_storage: 100) }

      before { stub_const('ENV', ENV.to_h.merge('WAREHOUSE_DATABASE_HOST' => 'my-host')) }

      it 'skips the instance and returns nil' do
        expect(described_class.resolve_instance).to be_nil
      end
    end

    context 'when CloudWatch returns no datapoints' do
      before do
        stub_const('ENV', ENV.to_h.merge('WAREHOUSE_DATABASE_HOST' => 'my-host.abc123.us-east-1.rds.amazonaws.com'))
        allow(GrdaWarehouse::DbMonitor::FreeStorageSpace).to receive(:call).and_return(nil)
      end

      it 'returns an RdsInstance with free_storage_gb nil' do
        result = described_class.resolve_instance
        expect(result.id).to eq('my-instance')
        expect(result.free_storage_gb).to be_nil
      end
    end
  end
end
