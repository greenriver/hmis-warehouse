###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Benchmarking
  # Serializes one benchmark run to a machine-readable JSON document combining
  # run identity (dataset, git state, environment) with the metrics the
  # importer already records (ImporterLog#phase_metrics and #summary).
  class Results
    attr_reader :label, :dataset, :data_source_id, :started_at, :finished_at, :importer_log, :loader_log, :git,
                :pg_stats, :other_active_connections

    def initialize(
      label:,
      dataset:,
      data_source_id:,
      started_at:,
      finished_at:,
      importer_log:,
      loader_log: nil,
      git: HmisCsvImporter::Benchmarking.git_info,
      pg_stats: nil,
      other_active_connections: nil
    )
      @label = label
      @dataset = dataset
      @data_source_id = data_source_id
      @started_at = started_at
      @finished_at = finished_at
      @importer_log = importer_log
      @loader_log = loader_log
      @git = git
      @pg_stats = pg_stats
      @other_active_connections = other_active_connections
    end

    def run_id
      stamp = started_at.utc.strftime('%Y%m%d_%H%M%S')
      return stamp if label.blank?

      "#{stamp}_#{label.to_s.parameterize(separator: '_')}"
    end

    def to_h
      {
        schema_version: 1,
        run_id: run_id,
        label: label,
        dataset: dataset,
        data_source_id: data_source_id,
        git: git,
        versions: {
          ruby: RUBY_VERSION,
          rails: Rails.version,
          postgres: GrdaWarehouseBase.connection.select_value('SHOW server_version'),
        },
        host: {
          hostname: Socket.gethostname,
          cpus: Etc.nprocessors,
        },
        started_at: started_at.utc.iso8601,
        finished_at: finished_at.utc.iso8601,
        total_seconds: (finished_at - started_at).to_f,
        importer_log_id: importer_log&.id,
        loader_log_id: loader_log&.id,
        loader_summary: loader_log&.summary,
        phases: phases,
        per_file: importer_log&.summary,
        pg_stats: pg_stats,
        other_active_connections: other_active_connections,
      }
    end

    def write!(dir: HmisCsvImporter::Benchmarking.results_dir)
      FileUtils.mkdir_p(dir)
      path = File.join(dir.to_s, "#{run_id}.json")
      File.write(path, JSON.pretty_generate(to_h))
      path
    end

    private

    # Phase metrics hold scalar timings plus arrays of captured slow queries
    # (see Importer#with_sql_log). The compressed query payloads are large and
    # stay in the ImporterLog; results keep only the durations for comparison.
    def phases
      (importer_log&.phase_metrics || {}).transform_values do |data|
        phase = {}
        slow_queries = {}
        data.each do |key, value|
          if value.is_a?(Array)
            slow_queries[key] = value.map { |query| query['duration'] }
          else
            phase[key] = value
          end
        end
        phase['slow_queries'] = slow_queries if slow_queries.any?
        phase
      end
    end
  end
end
