###
# Copyright Green River Data Group, Inc.
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
