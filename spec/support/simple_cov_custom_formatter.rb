# emits csv coverage report and rollups for areas of concern
require 'csv'

class SimpleCovCustomFormatter
  ROLLUPS = {
    hmis_models: [/\Adrivers\/hmis\/app\/models\/hmis\//],
    hmis_graphql_mutations: [/\Adrivers\/hmis\/app\/graphql\/mutations\//],
    hmis_graphql_types: [/\Adrivers\/hmis\/app\/graphql\/types\//],
    grda_warehouse_models: [/\Aapp\/models\/grda_warehouse\//],
  }.freeze

  def format(result)
    fn = File.join(SimpleCov.coverage_path, 'total_results.csv')

    rollup_values = {}
    ([:total] + ROLLUPS.keys).each do |key|
      rollup_values[key] = { missed: 0, covered: 0 }
    end

    CSV.open(fn, 'wb') do |csv|
      csv << ['File', 'Rollup', '% covered', 'Lines', 'Relevant Lines', 'Lines covered', 'Lines missed']

      result.files.each do |file|
        filename = filename_for(file)
        rollup_values[:total][:covered] += file.covered_lines.count
        rollup_values[:total][:missed] += file.missed_lines.count
        rollup = ROLLUPS.keys.detect do |key|
          patterns = ROLLUPS[key]
          next unless patterns.any? { |p| filename =~ p }

          rollup_values[key][:covered] += file.covered_lines.count
          rollup_values[key][:missed] += file.missed_lines.count
          true
        end
        row = [
          filename,
          rollup,
          file.covered_percent.round,
          file.lines.count,
          file.covered_lines.count + file.missed_lines.count,
          file.covered_lines.count,
          file.missed_lines.count,
        ]
        csv << row
      end
    end

    rollup_fn = File.join(SimpleCov.coverage_path, 'rollup_results.csv')
    CSV.open(rollup_fn, 'wb') do |csv|
      csv << ['Rollup', '% covered', 'Relevant Lines', 'Lines covered', 'Lines missed']
      rollup_values.each_pair do |key, values|
        covered, missed = values.values_at(:covered, :missed)
        total = covered + missed
        rate = covered.to_f / total
        pct = rate.finite? ? (rate * 100).round(2) : 0
        csv << [key, pct, total, covered, missed]
      end
    end
  end

  def filename_for(file)
    file.filename.sub(/\A#{SimpleCov.root}\//, '')
  end
end
