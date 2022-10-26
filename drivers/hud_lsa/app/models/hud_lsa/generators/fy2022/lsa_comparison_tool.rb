###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'csv'
module HudLsa::Generators::Fy2022
  class LsaComparisonTool
    attr_accessor :sample_data_path, :generated_data_path

    def initialize(sample_data_path, generated_data_path)
      @sample_data_path = sample_data_path
      @generated_data_path = generated_data_path
    end

    def compare
      comparisons = {}
      sample_data.each do |filepath|
        comparisons[filepath] = generate_diff(filepath, generated_data(filepath))
      end
      comparisons
    end

    def sample_data
      Dir.glob("#{sample_data_path}/*")
    end

    def generated_data(filepath)
      @generated_data ||= Dir.glob("#{generated_data_path}/*").index_by { |f| File.basename(f) }
      @generated_data[File.basename(filepath)]
    end

    def generate_diff(sample, gen)
      {
        'sample - generated' => file_contents(sample) - file_contents(gen),
        'generated - sample' => file_contents(gen) - file_contents(sample),
      }
    end

    def file_contents(filename)
      [].tap do |data|
        CSV.foreach(filename, headers: true) do |row|
          data << row.to_h.except(*removed_keys).values.map(&:to_s)
        end
      end.sort
    end

    # These keys will differ by run/installation, so just ignore them
    def removed_keys
      [
        'FunderID',
        'ProjectID',
        'ExportID',
        'InventoryID',
        'ReportID',
        'ReportDate',
        'SoftwareVendor',
        'SoftwareName',
        'VendorContact',
        'VendorEmail',
        'OrganizationID',
        'ProjectCoCID',
      ]
    end
  end
end
