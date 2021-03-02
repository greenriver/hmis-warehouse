###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class SchemaMigration < HealthBase
    def self.all_versions
      order(:version).pluck(:version)
    end
  end
end
