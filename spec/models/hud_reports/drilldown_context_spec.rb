###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::DrilldownContext, type: :model do
  let(:report) { instance_double('HudReports::ReportInstance', id: 123) }
  let(:generator) do
    double('Generator',
           file_prefix: 'TEST',
           column_headings: { 'client_id' => 'Client ID', 'name' => 'Name' },
           pii_columns: ['name'])
  end

  describe '.build' do
    it 'sanitizes cell_id' do
      context = described_class.build(report: report, generator: generator, measure_id: 'Q1', cell_id: 'A1; DROP TABLE users', table_id: 'T1')
      expect(context.cell).to eq('A1')
    end

    it 'sanitizes table_id' do
      context = described_class.build(report: report, generator: generator, measure_id: 'Q1', cell_id: 'A1', table_id: 'T1!')
      expect(context.table).to eq('T1')
    end

    it 'sanitizes measure_id via generator if supported' do
      allow(generator).to receive(:respond_to?).with(:valid_question_number).and_return(true)
      allow(generator).to receive(:method).with(:valid_question_number).and_return(double(owner: 'Other'))
      allow(generator).to receive(:valid_question_number).with('Q1').and_return('Validated Q1')

      context = described_class.build(report: report, generator: generator, measure_id: 'Q1', cell_id: 'A1', table_id: 'T1')
      expect(context.measure).to eq('Validated Q1')
    end
  end

  describe '#name' do
    it 'constructs name from components' do
      context = described_class.new(generator: generator, measure: 'Q1', table: 'T1', cell: 'A1')
      expect(context.name).to eq('TEST: Q1 / Table T1 / Cell A1')
    end

    it 'omits table and cell if missing' do
      context = described_class.new(generator: generator, measure: 'Q1')
      expect(context.name).to eq('TEST: Q1')
    end
  end

  describe '#query_params' do
    it 'returns a hash of relevant identifiers' do
      context = described_class.new(measure: 'Q1', table: 'T1', cell: 'A1', report_type: 'apr')
      expect(context.query_params).to eq({
        question: 'Q1',
        measure_id: 'Q1',
        cell_id: 'A1',
        id: 'A1',
        table: 'T1',
        report_type: 'apr'
      })
    end
  end

  describe '#export_headers' do
    before do
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)
      allow(generator).to receive(:respond_to?).with(:pii_columns).and_return(true)
    end

    it 'filters PII columns by default' do
      context = described_class.new(generator: generator, measure: 'Q1')
      expect(context.export_headers.keys).to eq(['client_id'])
      expect(context.export_headers.keys).not_to include('name')
    end

    it 'includes PII if configured' do
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(true)
      context = described_class.new(generator: generator, measure: 'Q1')
      expect(context.export_headers.keys).to include('name')
    end
  end

  describe 'search logic' do
    let(:model) { double('ClientModel') }
    let(:base_scope) { double('ActiveRecord::Relation', model: model) }

    before do
      allow(generator).to receive(:respond_to?).with(:client_scope).and_return(false)
      allow(generator).to receive(:client_class).and_return(model)
    end

    it 'is searchable? if model responds to searchable?' do
      context = described_class.new(generator: generator)
      allow(context).to receive(:base_scope).and_return(base_scope)

      allow(model).to receive(:respond_to?).with(:searchable?).and_return(true)
      allow(model).to receive(:searchable?).and_return(true)
      expect(context.searchable?).to be true
    end

    describe '#filtered_scope' do
      it 'applies search_clients to base_scope when searching' do
        context = described_class.new(generator: generator, search_term: 'John')
        allow(context).to receive(:base_scope).and_return(base_scope)
        allow(context).to receive(:searchable?).and_return(true)

        allow(model).to receive(:respond_to?).with(:search_clients).and_return(true)
        expect(model).to receive(:search_clients).with(base_scope, 'John').and_return(:filtered)

        expect(context.filtered_scope).to eq(:filtered)
      end

      it 'returns base_scope if not searchable' do
        context = described_class.new(generator: generator, search_term: 'John')
        allow(context).to receive(:base_scope).and_return(base_scope)
        allow(context).to receive(:searchable?).and_return(false)

        expect(context.filtered_scope).to eq(base_scope)
      end
    end
  end

  describe '#base_scope' do
    let(:model) { double('ClientModel') }
    let(:scope) { double('Scope') }
    let(:report_cell_scope) { double('ReportCellScope') }

    it 'builds scope using joins and merges' do
      context = described_class.new(report: report, generator: generator, measure: 'Q1', table: 'T1', cell: 'A1')

      allow(generator).to receive(:respond_to?).with(:client_scope).and_return(true)
      allow(generator).to receive(:client_scope).with('Q1').and_return(scope)

      expect(scope).to receive(:joins).with(hud_reports_universe_members: { report_cell: :report_instance }).and_return(scope)
      expect(scope).to receive(:merge).twice.and_return(scope)
      expect(scope).to receive(:distinct).and_return(:final_scope)

      # Mocking HudReports::ReportCell and HudReports::ReportInstance would be better but complex due to static methods
      # For now, we trust the chain if we can't easily mock the classes
      allow(HudReports::ReportCell).to receive(:for_table).and_return(report_cell_scope)
      allow(report_cell_scope).to receive(:for_cell).and_return(report_cell_scope)
      allow(HudReports::ReportInstance).to receive(:where).and_return(double(merge: scope))

      expect(context.base_scope).to eq(:final_scope)
    end
  end
end
