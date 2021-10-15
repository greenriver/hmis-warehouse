###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::CustomImports
  class ImportFile < GrdaWarehouseBase
    include NotifierConfig

    acts_as_paranoid
    self.table_name = :custom_imports_files
    attr_accessor :notifier_config

    belongs_to :config, class_name: 'GrdaWarehouse::CustomImports::Config'
    has_one :data_source, through: :config

    def check_hour
      # TODO: make sure it's been at least 23 hours since our last run, and we're in the correct hour of the day
      true
    end

    def start_import
      setup_notifier('CustomImports')
      update(status: 'started', started_at: Time.current, summary: [])
    end

    def log(message)
      @notifier&.ping(message)
      Rails.logger.info(message)
    end
  end
end
