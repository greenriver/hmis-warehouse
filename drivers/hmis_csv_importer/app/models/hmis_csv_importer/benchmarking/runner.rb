###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Benchmarking
  # Runs one benchmark: imports a dataset of HMIS CSVs into the given data
  # source through the standard auto-migrate pipeline, then writes a results
  # JSON document for later comparison.
  class Runner
    attr_reader :dataset, :data_source_id, :label, :results_dir

    def initialize(
      dataset_path:,
      data_source_id:,
      label: nil,
      results_dir: HmisCsvImporter::Benchmarking.results_dir
    )
      @dataset = Dataset.new(dataset_path)
      @data_source_id = data_source_id
      @label = label
      @results_dir = results_dir
    end

    # Returns the path of the written results JSON.
    def run!
      HmisCsvImporter::Benchmarking.ensure_not_production!
      git = HmisCsvImporter::Benchmarking.git_identity!

      started_at = Time.current
      importer = with_work_dir { |work_dir| import!(work_dir) }
      finished_at = Time.current
      raise 'Import did not produce an importer log; check the loader log for load failures' if importer.importer_log.blank?

      Results.new(
        label: label,
        dataset: dataset.to_h,
        data_source_id: data_source_id,
        started_at: started_at,
        finished_at: finished_at,
        importer_log: importer.importer_log,
        loader_log: importer.loader_log,
        git: git,
      ).write!(dir: results_dir)
    end

    private

    # The importer mutates its working directory (it writes a zip alongside the
    # CSVs), so each run works on a disposable copy of the dataset.
    def with_work_dir
      Dir.mktmpdir('benchmark_import', Rails.root.join('tmp')) do |dir|
        FileUtils.cp_r(File.join(dataset.csv_dir, '.'), dir)
        yield dir
      end
    end

    def import!(work_dir)
      importer = Importers::HmisAutoMigrate::Local.new(
        file_path: work_dir,
        data_source_id: data_source_id,
        project_cleanup: false,
      )
      importer.import!
      importer
    end
  end
end
