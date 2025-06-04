###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate do
  describe '.apply_migrations' do
    let(:csv_dir_2022) { 'spec/fixtures/files/importers/twenty_twenty_two/baseline' }
    let(:csv_dir_2024) { 'spec/fixtures/files/importers/twenty_twenty_four/baseline' }
    let(:csv_dir_2026) { 'spec/fixtures/files/importers/twenty_twenty_six/baseline' }
    let(:csv_tmp_dir) { 'tmp/test' }
    let(:notifier) { nil }

    before(:each) do
      allow(Rails.env).to receive(:production?).and_return(false)
      allow(Rails.env).to receive(:staging?).and_return(false)
      FileUtils.rm_rf(csv_tmp_dir)
      FileUtils.mkdir_p(csv_tmp_dir)
    end

    after(:each) do
      FileUtils.rm_rf(csv_tmp_dir)
    end

    context 'in development and testing environments' do
      it 'returns 2026 for any version' do
        FileUtils.cp_r(Dir.glob(File.join(csv_dir_2022, '*')), csv_tmp_dir)
        expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
      end
    end

    context 'in production environment' do
      before(:each) do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context 'before October 1st, 2025' do
        it 'returns 2024 for version 2022' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2022, '*')), csv_tmp_dir)

          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2024' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2024, '*')), csv_tmp_dir)
          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2026' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2026, '*')), csv_tmp_dir)
          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end
      end

      context 'on or after October 1st, 2025' do
        it 'returns 2026 for version 2022' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2022, '*')), csv_tmp_dir)

          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2024' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2024, '*')), csv_tmp_dir)
          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2026' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2026, '*')), csv_tmp_dir)
          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end
      end
    end

    context 'in staging environment' do
      before(:each) do
        allow(Rails.env).to receive(:staging?).and_return(true)
      end

      context 'before September 1st, 2025' do
        it 'returns 2024 for version 2022' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2022, '*')), csv_tmp_dir)

          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2024' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2024, '*')), csv_tmp_dir)
          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2026' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2026, '*')), csv_tmp_dir)
          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end
      end

      context 'on or after September 1st, 2025' do
        it 'returns 2026 for version 2022' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2022, '*')), csv_tmp_dir)

          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2024' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2024, '*')), csv_tmp_dir)
          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2026' do
          FileUtils.cp_r(Dir.glob(File.join(csv_dir_2026, '*')), csv_tmp_dir)
          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_tmp_dir, notifier)).to eq('2026')
          end
        end
      end
    end
  end
end
