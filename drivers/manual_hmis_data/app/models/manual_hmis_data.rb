###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/warehouse/data-sources-and-imports.md
module ManualHmisData
  def self.table_name_prefix
    'manual_hmis_datum_'
  end
end
