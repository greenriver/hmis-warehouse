###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Only covers the pieces of CiIntegrationCheck that are pure Ruby (no SQL Server
# connection, no report generation): scope validation, option-building, and the
# known-gap lookup. #run!, #compare, and #verify_files_present! drive/depend on
# real LSA generation and LsaSqlServer, which require an actual SQL Server
# connection to even load, so they're only exercised by the CI integration job
# itself (see driver:hud_lsa:ci_integration_test).
RSpec.describe HudLsa::Fy2026::CiIntegrationCheck do
  describe '.new' do
    it 'accepts the known scopes' do
      expect { described_class.new(scope: :lsa) }.not_to raise_error
      expect { described_class.new(scope: :hic) }.not_to raise_error
    end

    it 'raises ArgumentError for an unknown scope' do
      expect { described_class.new(scope: :bogus) }.to raise_error(ArgumentError, /unknown scope: :bogus/)
    end
  end

  describe '#report_options' do
    it 'builds a one-year lookback window ending today, with the System-Wide LSA scope, for :lsa' do
      travel_to(Time.zone.local(2026, 3, 15)) do
        options = described_class.new(scope: :lsa).report_options

        # Date#to_s is app-overridden to a human format, so parse rather than
        # comparing against a hard-coded ISO string.
        expect(Date.parse(options[:start])).to eq(Date.new(2025, 3, 1))
        expect(Date.parse(options[:end])).to eq(Date.new(2026, 3, 15))
        expect(options[:coc_code]).to eq('XX-501')
        expect(options[:lsa_scope]).to eq(1)
      end
    end

    it 'uses the HIC lsa_scope, distinct from the :lsa scope, for :hic' do
      travel_to(Time.zone.local(2026, 3, 15)) do
        lsa_options = described_class.new(scope: :lsa).report_options
        hic_options = described_class.new(scope: :hic).report_options

        expect(hic_options[:lsa_scope]).to eq(HudLsa::Fy2026::Report.available_lsa_scopes.fetch('HIC'))
        expect(hic_options[:lsa_scope]).not_to eq(lsa_options[:lsa_scope])
        # start/end/coc_code aren't scope-dependent
        expect(hic_options.except(:lsa_scope)).to eq(lsa_options.except(:lsa_scope))
      end
    end
  end

  describe '#known_sample_data_gaps' do
    it 'returns only the LSA-specific known gaps for :lsa' do
      expect(described_class.new(scope: :lsa).known_sample_data_gaps).to eq(
        'LSAReport.csv' => { columns: ['NoCoC'] },
        'LSACalculated.csv' => { rows: { 'ReportRow' => ['905'] } },
      )
    end

    it 'returns only the HIC-specific known gaps for :hic' do
      expect(described_class.new(scope: :hic).known_sample_data_gaps).to eq(
        'LSAReport.csv' => { columns: ['NoCoC'] },
        'Funder.csv' => { skip_file: true },
        'Inventory.csv' => { skip_file: true },
      )
    end
  end
end
