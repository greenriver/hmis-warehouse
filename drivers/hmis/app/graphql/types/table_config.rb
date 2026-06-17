###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableConfig < Types::BaseObject
    skip_activity_log
    # backed by Hmis::TableConfiguration

    field :columns, [Types::TableColumnConfig], null: false, default_value: []
    field :filters, [Types::TableFilterConfig], null: false, default_value: []
  end
end
