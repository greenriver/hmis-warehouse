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

    it 'raises error for invalid column identifier' do
      expect { row_builder.append_cell_value(col: '123', value: 10) }.to raise_error(ArgumentError, /Invalid column identifier/)
      expect { row_builder.append_cell_value(col: 'b', value: 10) }.to raise_error(ArgumentError, /Invalid column identifier/)
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

    it 'correctly builds a multi-row, multi-column grid' do
      builder.add_header(label: 'Col B')
      builder.add_header(label: 'Col C')

      builder.append_row(label: 'Row 1') do |row|
        row.append_cell_value(value: 11)
        row.append_cell_value(value: 12)
      end

      builder.append_row(label: 'Row 2') do |row|
        row.append_cell_value(value: 21)
        row.append_cell_value(value: 22)
      end

      sheet.build(builder)

      # Check metadata
      expect(answer).to have_received(:update!).with(metadata: hash_including(
        header_row: ['', 'Col B', 'Col C'],
        row_labels: ['Row 1', 'Row 2'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 3,
      ))

      # Check cell values (Row 1 is index 2, Row 2 is index 3)
      expect(report).to have_received(:answer).with(question: question, cell: 'B2')
      expect(report).to have_received(:answer).with(question: question, cell: 'C2')
      expect(report).to have_received(:answer).with(question: question, cell: 'B3')
      expect(report).to have_received(:answer).with(question: question, cell: 'C3')

      # Check that all values were persisted
      expect(answer).to have_received(:update!).with(summary: 11)
      expect(answer).to have_received(:update!).with(summary: 12)
      expect(answer).to have_received(:update!).with(summary: 21)
      expect(answer).to have_received(:update!).with(summary: 22)
    end

    it 'allows building rows out of order and handles gaps' do
      builder.add_header(label: 'H1')

      # Set row 1 (0-indexed in builder, row 3 in sheet)
      builder.set_row(1, label: 'Row 2') do |row|
        row.append_cell_value(value: 20)
      end

      # Skip row 0 (row 2 in sheet) for now, build it later
      builder.set_row(0, label: 'Row 1') do |row|
        row.append_cell_value(value: 10)
      end

      # Set row 3 (leaving index 2 / row 4 empty)
      builder.set_row(3, label: 'Row 4') do |row|
        row.append_cell_value(value: 40)
      end

      sheet.build(builder)

      # Check metadata: row_labels should have empty string for the gap at index 2
      expect(answer).to have_received(:update!).with(metadata: hash_including(
        row_labels: ['Row 1', 'Row 2', '', 'Row 4'],
        last_row: 5, # indices 0-3 + start row 2 = 5
      ))

      # Verify persistence
      expect(report).to have_received(:answer).with(question: question, cell: 'B2')
      expect(report).to have_received(:answer).with(question: question, cell: 'B3')
      expect(report).to have_received(:answer).with(question: question, cell: 'B5')
      expect(answer).to have_received(:update!).with(summary: 10)
      expect(answer).to have_received(:update!).with(summary: 20)
      expect(answer).to have_received(:update!).with(summary: 40)
    end
  end

  describe '#cell_value' do
    let(:answer) { instance_double('HudReports::ReportCell', value: 123) }

    it 'returns the value for a given cell coordinate as a string' do
      allow(report).to receive(:answer).with(question: question, cell: 'B2').and_return(answer)
      expect(sheet.cell_value('B2')).to eq(123)
    end

    it 'returns the value for a given cell coordinate as an array' do
      allow(report).to receive(:answer).with(question: question, cell: 'C3').and_return(answer)
      expect(sheet.cell_value(['C', 3])).to eq(123)
    end

    it 'returns nil if the cell does not exist' do
      allow(report).to receive(:answer).with(question: question, cell: 'Z9').and_return(nil)
      expect(sheet.cell_value('Z9')).to be_nil
    end
  end
end
