###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :benchmark do
  # rails driver:hmis_csv_importer:benchmark:run['/path/to/dataset',2,'my label']
  desc 'Import a dataset directory of HMIS CSVs and record benchmark results'
  task :run, [:dataset_path, :data_source_id, :label] => [:environment] do |_task, args|
    raise 'dataset_path and data_source_id are required' if args.dataset_path.blank? || args.data_source_id.blank?

    path = HmisCsvImporter::Benchmarking::Runner.new(
      dataset_path: args.dataset_path,
      data_source_id: args.data_source_id.to_i,
      label: args.label,
    ).run!
    puts path
  end
end
