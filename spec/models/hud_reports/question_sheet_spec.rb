# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::QuestionSheet do
  let(:report) { build(:hud_reports_report_instance) }
  let(:question) { 'Q1' }
  subject(:sheet) { described_class.new(report: report, question: question) }

  describe '#initialize' do
    it 'accepts a valid question id' do
      expect { described_class.new(report: report, question: 'Q1') }.not_to raise_error
      expect { described_class.new(report: report, question: 'Q99') }.not_to raise_error
    end

    it 'raises an error for an invalid question id' do
      expect { described_class.new(report: report, question: '1') }.to raise_error(ArgumentError, /invalid question id/)
      expect { described_class.new(report: report, question: 'Question 1') }.to raise_error(ArgumentError, /invalid question id/)
    end
  end

  describe 'QuestionSheetBuilder' do
    let(:builder) { sheet.builder }

    it 'initializes with default header for column A' do
      expect(builder.headers).to eq({ 'A' => '' })
    end

    it 'adds headers correctly' do
      builder.add_header(label: 'Col 1')
      expect(builder.headers['B']).to eq('Col 1')

      builder.add_header(col: 'D', label: 'Col D')
      expect(builder.headers['D']).to eq('Col D')
    end

    it 'calculates next_column correctly' do
      expect(builder.send(:next_column)).to eq('B')
      builder.add_header(label: 'Col 1') # B
      expect(builder.send(:next_column)).to eq('C')
    end
  end

  describe 'QuestionSheetRowBuilder' do
    let(:row_builder) { HudReports::QuestionSheetRowBuilder.new(label: 'Row 1') }

    it 'initializes with label' do
      expect(row_builder.label).to eq('Row 1')
    end

    it 'appends cell members' do
      members = [double('Member')]
      col = row_builder.append_cell_members(members: members)
      expect(col).to eq('B')
      expect(row_builder.cell_members['B']).to eq(members)
    end

    it 'appends cell values' do
      col = row_builder.append_cell_value(value: 100)
      expect(col).to eq('B')
      expect(row_builder.cell_values['B']).to eq(100)
    end

    it 'raises error for duplicate column in the same row' do
      row_builder.append_cell_value(col: 'B', value: 10)
      expect { row_builder.append_cell_value(col: 'B', value: 20) }.to raise_error(ArgumentError, /already defined/)
      expect { row_builder.append_cell_members(col: 'B', members: []) }.to raise_error(ArgumentError, /already defined/)
    end

    it 'calculates next_column starting from B' do
      expect(row_builder.send(:next_column)).to eq('B')
      row_builder.append_cell_value(value: 1) # B
      expect(row_builder.send(:next_column)).to eq('C')
    end
  end

  describe '#build' do
    let(:builder) { sheet.builder }
    let(:answer) { instance_double('HudReports::ReportCell') }

    before do
      allow(report).to receive(:answer).and_return(answer)
      allow(answer).to receive(:update!)
      allow(answer).to receive(:add_members)
    end

    it 'updates metadata with headers and row labels' do
      builder.add_header(label: 'Header B')
      builder.append_row(label: 'Row 1') do |row|
        row.append_cell_value(value: 10)
      end

      sheet.build(builder)

      expect(report).to have_received(:answer).with(question: question)
      expect(answer).to have_received(:update!).with(metadata: hash_including(
        header_row: ['', 'Header B'],
        row_labels: ['Row 1'],
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 2,
      ))
    end

    it 'persists cell values' do
      builder.add_header(label: 'H1')
      builder.append_row(label: 'R1') do |row|
        row.append_cell_value(value: 42)
      end

      sheet.build(builder)

      expect(report).to have_received(:answer).with(question: question, cell: 'B2')
      expect(answer).to have_received(:update!).with(summary: 42)
    end

    it 'persists cell members and updates summary with count' do
      members = [double('M1'), double('M2')]
      builder.add_header(label: 'H1')
      builder.append_row(label: 'R1') do |row|
        row.append_cell_members(members: members)
      end

      sheet.build(builder)

      expect(report).to have_received(:answer).with(question: question, cell: 'B2')
      expect(answer).to have_received(:add_members).with(members)
      expect(answer).to have_received(:update!).with(summary: 2)
    end

    it 'allows value to override members count summary' do
      members = [double('M1'), double('M2')]
      builder.add_header(label: 'H1')
      builder.append_row(label: 'R1') do |row|
        row.append_cell_members(members: members, value: 99)
      end

      sheet.build(builder)

      # Pass 1 from cell_members update
      expect(answer).to have_received(:update!).with(summary: 2)
      # Pass 2 from cell_values update (the override)
      expect(answer).to have_received(:update!).with(summary: 99)
    end
  end
end
