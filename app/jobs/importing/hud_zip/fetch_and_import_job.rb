###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing::HudZip
  class FetchAndImportJob < BaseJob
    queue_as :low_priority

    def perform(klass:, options:)
      safe_klass = known_classes.detect { |m| klass == m }
      raise "Unknown import class: #{klass}; You must add it to the whitelist in FetchAndImportJob" unless safe_klass.present?

      safe_klass.constantize.new(options).import!
    end

    def max_attempts
      1
    end

    def known_classes
      [
        'Importers::HMISSixOneOne::Sftp',
        'Importers::HmisTwentyTwenty::Sftp',
        'Importers::HMISSixOneOne::S3',
        'Importers::HmisTwentyTwenty::S3',
      ].freeze
    end
  end
end
