###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Aggregated
  class Base
    include HmisCsvImporter::HmisCsv

    attr_accessor :importer_log, :date_range

    def initialize(importer_log:, date_range:, version:)
      @importer_log = importer_log
      @date_range = date_range
      @current_version = version
    end

    def aggregate!
      raise 'aggregate! must be implemented'
    end

    def self.description
      name.split('::').last.underscore.humanize
    end

    def self.associated_model
      # NOTE: This assumes an enable contains a single element
      enable[:import_aggregators].keys.first
    end

    def self.checked?(data_source)
      # NOTE: This assumes an enable contains a single element
      enabled_key = enable[:import_aggregators].keys.first
      data_source[:import_aggregators][enabled_key.to_s]&.include?(enable[:import_aggregators][enabled_key].first) || false
    end
  end
end
