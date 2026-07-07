###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::Generators::RetiredLsaStub, type: :model do
  # Use Fy2024::Lsa as the concrete includer under test.
  let(:klass) { HudLsa::Generators::Fy2024::Lsa }

  def create_lsa_report(**options_hash)
    record = create(
      :hud_reports_report_instance,
      type: 'HudLsa::Generators::Fy2024::Lsa',
      options: options_hash,
      question_names: [],
    )
    klass.find(record.id)
  end

  # -- Class methods -----------------------------------------------------------

  describe '.generic_title' do
    it 'returns the human-readable product name' do
      expect(klass.generic_title).to eq('Longitudinal System Analysis')
    end
  end

  describe '.short_name' do
    it 'returns LSA' do
      expect(klass.short_name).to eq('LSA')
    end
  end

  describe '.title' do
    it 'combines generic_title with fiscal_year' do
      expect(klass.title).to eq('Longitudinal System Analysis - FY 2024')
    end
  end

  describe '.fiscal_year' do
    it 'returns the FY string derived from the module namespace' do
      expect(klass.fiscal_year).to eq('FY 2024')
    end
  end

  describe '.questions' do
    it 'maps the LSA key to the class itself' do
      expect(klass.questions).to eq({ 'LSA' => klass })
    end
  end

  describe '.table_descriptions' do
    it 'maps LSA to the human-readable description' do
      expect(klass.table_descriptions).to eq({ 'LSA' => 'All LSA Data' })
    end
  end

  describe '.describe_table' do
    it 'returns the description for a known table' do
      expect(klass.describe_table('LSA')).to eq('All LSA Data')
    end

    it 'returns nil for an unknown table' do
      expect(klass.describe_table('nonexistent')).to be_nil
    end
  end

  describe '.allowed_options' do
    context 'for a non-HIC report (lsa_scope: 1)' do
      let(:report) { create_lsa_report(lsa_scope: 1) }

      it 'includes :coc_code, :lsa_scope, :start, and :end' do
        expect(klass.allowed_options(report)).to include(:coc_code, :lsa_scope, :start, :end)
      end

      it 'does not include :on' do
        expect(klass.allowed_options(report)).not_to include(:on)
      end
    end

    context 'for a HIC report (lsa_scope: HIC value)' do
      let(:report) { create_lsa_report(lsa_scope: HudLsa::Fy2026::Report.available_lsa_scopes['HIC']) }

      it 'includes :on' do
        expect(klass.allowed_options(report)).to include(:on)
      end

      it 'does not include :start or :end' do
        opts = klass.allowed_options(report)
        expect(opts).not_to include(:start)
        expect(opts).not_to include(:end)
      end
    end
  end

  # -- Instance methods --------------------------------------------------------

  describe '#hic?' do
    it 'returns false when lsa_scope is 1' do
      expect(create_lsa_report(lsa_scope: 1)).not_to be_hic
    end

    it 'returns false when lsa_scope is nil' do
      expect(create_lsa_report).not_to be_hic
    end

    it 'returns true when lsa_scope is the HIC integer value' do
      expect(create_lsa_report(lsa_scope: HudLsa::Fy2026::Report.available_lsa_scopes['HIC'])).to be_hic
    end

    it 'returns true when lsa_scope is the HIC value as a string (JSONB stores options values as strings)' do
      expect(create_lsa_report(lsa_scope: HudLsa::Fy2026::Report.available_lsa_scopes['HIC'].to_s)).to be_hic
    end
  end

  # -- STI resolution ----------------------------------------------------------

  describe 'STI resolution' do
    it 'instantiates as Fy2024::Lsa when loaded via HudReports::ReportInstance' do
      create(:hud_reports_report_instance, type: 'HudLsa::Generators::Fy2024::Lsa', options: {}, question_names: [])
      result = HudReports::ReportInstance.where(type: 'HudLsa::Generators::Fy2024::Lsa').first
      expect(result).to be_a(HudLsa::Generators::Fy2024::Lsa)
    end
  end

  describe 'generation is disabled' do
    it 'does not define a local run! method (cannot generate new reports)' do
      expect(klass.instance_methods(false)).not_to include(:run!)
    end
  end
end
