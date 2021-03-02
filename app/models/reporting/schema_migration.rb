###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class SchemaMigration < ReportingBase
    def self.all_versions
      order(:version).pluck(:version)
    end
  end
end
