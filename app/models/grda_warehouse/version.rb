###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Version < GrdaWarehouseBase
    include PaperTrail::VersionConcern

    # overlay object changes onto object
    def object_with_changes
      # create events have object_changes and a nil object
      result = object&.dup || {}
      result.merge!(object_changes.transform_values(&:last)) if object_changes.present?
      result
    end
  end
end
