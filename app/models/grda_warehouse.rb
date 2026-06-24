###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  def self.table_name_prefix
    ''
  end

  def self.paper_trail_versions
    GrdaWarehouse::Version.all
  end
end
