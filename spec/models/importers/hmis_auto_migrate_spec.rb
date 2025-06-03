###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate do
  describe '.apply_migrations' do
    let(:csv_dir) { 'spec/fixtures/files/importers/twenty_twenty_four/enrollment_test_files/source' }
    let(:notifier) { nil }

    before(:each) do
      allow(Rails.env).to receive(:production?).and_return(false)
      allow(Rails.env).to receive(:staging?).and_return(false)
    end

    context 'in development and testing environments' do
      it 'returns 2026 for any version' do
        allow(described_class).to receive(:calculate_current_version).and_return('2022')
        expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
      end
    end

    context 'in production environment' do
      before(:each) do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context 'before October 1st, 2025' do
        it 'returns 2024 for version 2022' do
          allow(described_class).to receive(:calculate_current_version).and_return('2022')
          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2024' do
          allow(described_class).to receive(:calculate_current_version).and_return('2024')
          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2026' do
          allow(described_class).to receive(:calculate_current_version).and_return('2026')
          travel_to '2025-09-30' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end
      end

      context 'on or after October 1st, 2025' do
        it 'returns 2026 for version 2022' do
          allow(described_class).to receive(:calculate_current_version).and_return('2022')
          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2024' do
          allow(described_class).to receive(:calculate_current_version).and_return('2024')
          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2026' do
          allow(described_class).to receive(:calculate_current_version).and_return('2026')
          travel_to '2025-10-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
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
          allow(described_class).to receive(:calculate_current_version).and_return('2022')
          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2024' do
          allow(described_class).to receive(:calculate_current_version).and_return('2024')
          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2024')
          end
        end

        it 'returns provided version for 2026' do
          allow(described_class).to receive(:calculate_current_version).and_return('2026')
          travel_to '2025-08-31' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end
      end

      context 'on or after September 1st, 2025' do
        it 'returns 2026 for version 2022' do
          allow(described_class).to receive(:calculate_current_version).and_return('2022')
          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2024' do
          allow(described_class).to receive(:calculate_current_version).and_return('2024')
          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end

        it 'returns 2026 for version 2026' do
          allow(described_class).to receive(:calculate_current_version).and_return('2026')
          travel_to '2025-09-01' do
            expect(described_class.apply_migrations(csv_dir, notifier)).to eq('2026')
          end
        end
      end
    end
  end
end
