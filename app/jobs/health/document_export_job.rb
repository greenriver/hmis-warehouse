###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class DocumentExportJob < BaseJob
    extend ActiveSupport::Concern
    queue_as :default

    protected def export_scope
      Health::DocumentExport
    end
  end
end
