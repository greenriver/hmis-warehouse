###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::RunnerJob, type: :job do
  let!(:data_source) { create(:hmis_data_source) }
  let(:run_date)     { Date.new(2026, 1, 15) }

  let(:base_config) do
    {
      'name' => 'Runner Test CoC',
      'data_source_id' => data_source.id,
      'seed' => 77,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Test Org_',
          'projects' => [
            { 'name' => 'Test ES_', 'project_type' => 1, 'capacity' => 20 },
          ],
        },
      ],
      'household_templates' => {
        'adult_only' => {
          'hoh' => {
            'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 },
            'gender' => { 'woman' => 0.5, 'man' => 0.5 },
            'veteran_probability' => 0.0,
            'race' => { 'white' => 1.0 },
          },
        },
      },
      'populations' => [
        { 'name' => 'street', 'label' => 'Street', 'project_ref' => 'Test ES_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 1, 'exit_point' => 0.1 },
      ],
      'transitions' => [],
      'enrollment_config' => {
        'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 30 },
      },
    }
  end

  let(:config_key) { 'hmis_simulation/runner-test-coc' }
  let(:config)     { HmisSimulation::ConfigLoader.send(:normalize, base_config) }

  before do
    User.setup_system_user
    AppConfigProperty.where(key: config_key).delete_all
    HmisSimulation::ConfigLoader.upsert_app_config(config_key, config)
    HmisSimulation::Bootstrapper.new(config).run!
  end

  after do
    AppConfigProperty.where(key: config_key).delete_all
  end

  describe '#perform' do
    context 'with no prior run logs (first ever run)' do
      it 'runs the engine for today only when no prior run exists' do
        travel_to(run_date) do
          described_class.perform_now(end_date: run_date)
          expect(HmisSimulation::RunLog.where(data_source_id: data_source.id, run_date: run_date).count).to eq(1)
        end
      end
    end

    context 'catch-up across missed days' do
      it 'processes all days between last successful run and today' do
        # Seed a run log for 3 days ago
        HmisSimulation::RunLog.create!(
          data_source_id: data_source.id,
          run_date: run_date - 3,
          started_at: Time.current,
          finished_at: Time.current,
          clients_created: 0,
        )

        travel_to(run_date) do
          described_class.perform_now(end_date: run_date)
          run_dates = HmisSimulation::RunLog.where(data_source_id: data_source.id).pluck(:run_date)
          expect(run_dates).to include(run_date - 2, run_date - 1, run_date)
        end
      end
    end

    context 'error isolation' do
      let(:config_key2) { 'hmis_simulation/broken-coc' }

      before do
        # A second config that references a non-existent data_source_id — engine will raise
        broken = base_config.merge('name' => 'Broken CoC', 'data_source_id' => 999_999)
        HmisSimulation::ConfigLoader.upsert_app_config(config_key2, broken)
      end

      after do
        AppConfigProperty.where(key: config_key2).delete_all
      end

      it 'does not raise even when one simulation config fails' do
        travel_to(run_date) do
          expect { described_class.perform_now(end_date: run_date) }.not_to raise_error
        end
      end

      it 'still runs valid simulations when one config fails' do
        travel_to(run_date) do
          described_class.perform_now(end_date: run_date)
          # The good simulation should have completed
          expect(HmisSimulation::RunLog.where(data_source_id: data_source.id, run_date: run_date).count).to eq(1)
        end
      end
    end

    context 'idempotency' do
      it 'does not create duplicate RunLog records on re-run' do
        travel_to(run_date) do
          described_class.perform_now(end_date: run_date)
          described_class.perform_now(end_date: run_date)
          expect(HmisSimulation::RunLog.where(data_source_id: data_source.id, run_date: run_date).count).to eq(1)
        end
      end
    end
  end
end
