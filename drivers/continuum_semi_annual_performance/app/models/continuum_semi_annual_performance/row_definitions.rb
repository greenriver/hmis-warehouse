###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  class RowDefinitions
    ALWAYS_BUILT_QUESTIONS = [7, 8].freeze

    def self.deep_freeze(value)
      case value
      when Hash then value.each_value { |v| deep_freeze(v) }
      when Array then value.each { |v| deep_freeze(v) }
      end
      value.freeze
    end
    private_class_method :deep_freeze

    DATA = deep_freeze(
      YAML.safe_load_file(
        File.expand_path('../../../config/rows.yml', __dir__),
        permitted_classes: [],
        symbolize_names: true,
      ),
    )

    def self.rows(row_set, project_type)
      project_type = project_type.to_sym
      rows_cache[[row_set.to_sym, project_type]] ||= entries(row_set, project_type).
        select { |entry| entry[:order]&.key?(project_type) }.
        sort_by { |entry| entry[:order][project_type] }.
        map { |entry| deep_freeze(build_row(entry, project_type)) }.
        freeze
    end

    def self.questions(row_set, project_type)
      numbers = rows(row_set, project_type).flat_map { |row| row[:cells] || [] }.map do |cell|
        cell[:table][/\AQ(\d+)/, 1].to_i
      end
      (numbers + ALWAYS_BUILT_QUESTIONS).uniq.sort.map { |number| "Question #{number}" }
    end

    def self.entries(row_set, project_type)
      section = row_set.to_sym == :end_of_year && project_type == :ce_tab ? :end_of_year_ce : row_set.to_sym
      DATA.fetch(section)
    end
    private_class_method :entries

    def self.rows_cache
      @rows_cache ||= {}
    end
    private_class_method :rows_cache

    def self.build_row(entry, project_type)
      row = { key: "r#{entry[:order][project_type]}", label: entry[:label], header: entry[:header] == true }
      return row.merge(level: entry[:level]) if row[:header]

      op = entry[:op].to_sym
      cells = entry[:cells].map { |cell| cell.slice(:report, :table, :cell) }
      cells = expand_range(cells) if op == :sum_range
      row.merge(format: entry[:format].to_sym, op: op == :sum_range ? :sum : op, cells: cells, source: entry[:source])
    end
    private_class_method :build_row

    def self.expand_range(endpoints)
      first, last = endpoints
      column = first[:cell][/\A[A-Z]+/]
      from = first[:cell][/\d+\z/].to_i
      to = last[:cell][/\d+\z/].to_i
      (from..to).map { |row_number| { report: first[:report], table: first[:table], cell: "#{column}#{row_number}" } }
    end
    private_class_method :expand_range
  end
end
