###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis
  module AcHmis
    def self.data_source
      # Note: not set up to handle multiple HMIS data sources, since ac_hmis doesn't need it. Expect exactly one.
      ::GrdaWarehouse::DataSource.hmis.sole
    end
  end
end
