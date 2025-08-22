###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
  end
end
