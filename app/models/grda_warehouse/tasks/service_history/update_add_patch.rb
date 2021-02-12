###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class UpdateAddPatch < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    attr_accessor :logger

    def run!
      process()
    end
  end
end
