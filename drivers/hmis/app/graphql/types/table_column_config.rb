###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableColumnConfig < Types::BaseObject
    skip_activity_log
    # backed by Hmis::TableConfiguration#columns object

    field :key, String, null: false
    field :label, String, null: false
    field :type, Types::TableColumnConfigType, null: false
  end
end
