###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::DrilldownContext, type: :model do
  # A concrete generator for testing behavior instead of mocking every method
  class TestGenerator < HudReports::GeneratorBase
    def self.file_prefix = 'TEST'
    def self.column_headings(_) = { 'client_id' => 'Client ID', 'name' => 'Name' }
    def self.pii_columns = ['name']
    def self.client_class(_) = GrdaWarehouse::Hud::Client
    def self.questions = { 'Q1' => Object }
  end

  # A generator that implements the custom measure validation
  class CustomValidationGenerator < TestGenerator
    def self.valid_question_number(id) = "Validated #{id}"
  end

  let(:report) { instance_double('HudReports::ReportInstance', id: 123) }
  let(:generator) { TestGenerator }

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
      context = described_class.build(report: report, generator: CustomValidationGenerator, measure_id: 'Q1', cell_id: 'A1', table_id: 'T1')
      expect(context.measure).to eq('Validated Q1')
    end

    it 'defaults to first question if measure_id invalid and questions defined' do
      context = described_class.build(report: report, generator: TestGenerator, measure_id: 'INVALID', cell_id: 'A1', table_id: 'T1')
      expect(context.measure).to eq('Q1')
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
                                           report_type: 'apr',
                                         })
    end
  end

  describe '#export_headers' do
    before do
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)
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

  describe 'searching' do
    let(:model) { double('ClientModel') }
    let(:base_scope) { double('ActiveRecord::Relation', model: model) }
    let(:context) { described_class.new(generator: generator, search_term: 'John') }

    before do
      allow(context).to receive(:base_scope).and_return(base_scope)
    end

    describe '#searchable?' do
      it 'is true if model is searchable' do
        allow(model).to receive(:respond_to?).with(:searchable?).and_return(true)
        allow(model).to receive(:searchable?).and_return(true)
        expect(context.searchable?).to be true
      end

      it 'is false if model is not searchable' do
        allow(model).to receive(:respond_to?).with(:searchable?).and_return(false)
        expect(context.searchable?).to be false
      end
    end

    describe '#filtered_scope' do
      it 'applies search_clients when searching' do
        allow(context).to receive(:searchable?).and_return(true)
        allow(model).to receive(:respond_to?).with(:search_clients).and_return(true)
        expect(model).to receive(:search_clients).with(base_scope, 'John').and_return(:filtered)

        expect(context.filtered_scope).to eq(:filtered)
      end

      it 'returns base_scope if search term is blank' do
        context.search_term = ''
        expect(context.filtered_scope).to eq(base_scope)
      end

      it 'returns base_scope if not searchable' do
        allow(context).to receive(:searchable?).and_return(false)
        expect(context.filtered_scope).to eq(base_scope)
      end
    end

    describe '#apply_search_query!' do
      it 'extracts search term from search query object' do
        search_query = double('SearchQuery', query_params: { q: 'Jane' })
        context.apply_search_query!(search_query)
        expect(context.search_term).to eq('Jane')
      end
    end
  end

  describe '#base_scope' do
    let(:client_scope) { double('ClientScope') }
    let(:report_cell_scope) { double('ReportCellScope') }
    let(:report_instance_scope) { double('ReportInstanceScope') }

    it 'builds the expected ActiveRecord relation chain' do
      context = described_class.new(report: report, generator: generator, measure: 'Q1', table: 'T1', cell: 'A1')

      # Mock the starting scope from the generator
      allow(generator).to receive(:client_class).with('Q1').and_return(client_scope)

      # Mock the chain of ActiveRecord methods. While still using mocks, we focus on
      # the functional requirements of the scope building.
      expect(client_scope).to receive(:joins).with(hud_reports_universe_members: { report_cell: :report_instance }).and_return(client_scope)
      expect(client_scope).to receive(:merge).with(report_cell_scope).and_return(client_scope)
      expect(client_scope).to receive(:merge).with(report_instance_scope).and_return(client_scope)
      expect(client_scope).to receive(:distinct).and_return(:final_scope)

      allow(HudReports::ReportCell).to receive(:for_table).with('T1').and_return(report_cell_scope)
      allow(report_cell_scope).to receive(:for_cell).with('A1').and_return(report_cell_scope)
      allow(HudReports::ReportInstance).to receive(:where).with(id: 123).and_return(report_instance_scope)

      expect(context.base_scope).to eq(:final_scope)
    end
  end
end
