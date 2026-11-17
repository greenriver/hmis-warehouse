###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'continuum_semi_annual_performance config/rows.yml shape' do
  let(:path) { Rails.root.join('drivers/continuum_semi_annual_performance/config/rows.yml') }
  let(:data) { YAML.safe_load_file(path) }
  let(:allowed_keys) { ['label', 'order', 'header', 'level', 'source', 'op', 'cells', 'format'] }
  let(:section_types) do
    { 'mid_year' => ['es', 'hp', 'so', 'rrh'], 'end_of_year' => ['es', 'hp', 'so', 'rrh'], 'end_of_year_ce' => ['ce'] }
  end

  def violations_for(section, entry, positions)
    problems = []
    flag = ->(msg) { problems << "#{section} / #{entry['label'].inspect}: #{msg}" }

    (entry.keys - allowed_keys).each { |key| flag.call("unknown key #{key}") }
    flag.call('blank label') if entry['label'].to_s.strip.empty?
    check_order(entry['order'], section, flag, positions, entry['label'])
    entry['header'] == true ? check_header(entry, flag) : check_data_row(entry, section, flag)
    problems
  end

  def check_order(order, section, flag, positions, label)
    return flag.call('order is not a hash') unless order.is_a?(Hash) && order.any?

    order.each do |type, position|
      flag.call("order key #{type} not allowed") unless section_types[section].include?(type)
      flag.call("order #{type} is not a positive integer: #{position.inspect}") unless position.is_a?(Integer) && position.positive?
      (positions[[type, position]] ||= []) << label
    end
  end

  def check_header(entry, flag)
    flag.call("header level must be 1 or 2: #{entry['level'].inspect}") unless [1, 2].include?(entry['level'])
    ['cells', 'op', 'format'].each { |key| flag.call("header has #{key}") if entry.key?(key) }
  end

  def check_data_row(entry, section, flag)
    flag.call('header is not true or absent') unless entry['header'].nil?
    flag.call('level on a data row') if entry.key?('level')
    flag.call("op #{entry['op'].inspect}") unless ['value', 'sum', 'sum_range'].include?(entry['op'])
    flag.call("format #{entry['format'].inspect}") unless ['count', 'percent', 'decimal'].include?(entry['format'])
    cells = entry['cells']
    return flag.call('cells empty') unless cells.is_a?(Array) && cells.any?

    expected_report = section == 'end_of_year_ce' ? 'ce_apr' : 'apr'
    cells.each { |cell| check_cell(cell, expected_report, flag) }
    check_cell_count(entry, cells, flag)
  end

  def check_cell(cell, expected_report, flag)
    return flag.call("cell is not a hash: #{cell.inspect}") unless cell.is_a?(Hash)

    flag.call("cell keys #{cell.keys.sort}") unless cell.keys.sort == ['cell', 'report', 'table']
    flag.call("cell report #{cell['report'].inspect}") unless cell['report'] == expected_report
    flag.call("cell table #{cell['table'].inspect}") unless cell['table'].to_s.match?(/\AQ\d+[a-z0-9]*\z/)
    flag.call("cell ref #{cell['cell'].inspect}") unless cell['cell'].to_s.match?(/\A[A-Z]+\d+\z/)
  end

  def check_cell_count(entry, cells, flag)
    if entry['op'] == 'value'
      flag.call("value row has #{cells.size} cells") unless cells.size == 1
    elsif entry['op'] == 'sum'
      flag.call('sum row has fewer than 2 cells') if cells.size < 2
    elsif entry['op'] == 'sum_range'
      flag.call("sum_range row has #{cells.size} cells") unless cells.size == 2
      return unless cells.size == 2 && cells.all? { |c| c.is_a?(Hash) }

      flag.call('sum_range cells differ in table') unless cells.map { |c| c['table'] }.uniq.size == 1
      flag.call('sum_range cells differ in column') unless cells.map { |c| c['cell'].to_s[/\A[A-Z]+/] }.uniq.size == 1
      first, last = cells.map { |c| c['cell'].to_s[/\d+\z/].to_i }
      flag.call("sum_range start row #{first} is after end row #{last}") if first > last
    end
  end

  it 'has exactly the expected sections' do
    expect(data.keys).to match_array(section_types.keys)
  end

  def problems_in(sections)
    sections.slice(*section_types.keys).flat_map do |section, entries|
      positions = {}
      found = entries.flat_map { |entry| violations_for(section, entry, positions) }
      duplicates = positions.select { |_, labels| labels.size > 1 }.map do |(type, position), labels|
        "#{section}: #{type} position #{position} shared by #{labels.map(&:inspect).join(', ')}"
      end
      found + duplicates
    end
  end

  it 'has well-formed entries in every section' do
    expect(problems_in(data)).to eq([])
  end

  it 'flags a sum_range that starts after it ends' do
    reversed = {
      'mid_year' => [
        {
          'label' => 'Reversed', 'order' => { 'es' => 1 }, 'op' => 'sum_range', 'format' => 'count',
          'cells' => [{ 'report' => 'apr', 'table' => 'Q7a', 'cell' => 'B9' }, { 'report' => 'apr', 'table' => 'Q7a', 'cell' => 'B3' }]
        },
      ],
    }

    expect(problems_in(reversed)).to eq(['mid_year / "Reversed": sum_range start row 9 is after end row 3'])
  end
end
