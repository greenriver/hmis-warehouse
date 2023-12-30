###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  def self.table_name_prefix
    ''
  end

  def self.paper_trail_versions
    GrdaWarehouse::Version.all
  end
end
