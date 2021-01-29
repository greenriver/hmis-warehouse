###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportJob < ApplicationJob
  include DocumentExportJobBehavior
  queue_as :default

  protected def export_scope
    GrdaWarehouse::DocumentExport
  end
end
