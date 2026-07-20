###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module TxClientReports
  class ResearchExports::Export < GrdaWarehouse::File
    belongs_to :user
    belongs_to :file, class_name: 'GrdaWarehouse::File', optional: true
  end
end
