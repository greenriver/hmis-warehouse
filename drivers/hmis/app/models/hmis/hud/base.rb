###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Base < ::GrdaWarehouseBase
  self.abstract_class = true

  acts_as_paranoid(column: :DateDeleted)

  def self.hmis_relation(col, model_name = nil)
    h = {
      primary_key: [
        :data_source_id,
        col,
      ],
      foreign_key: [
        :data_source_id,
        col,
      ],
      autosave: false,
    }
    h.merge! class_name: "Hmis::Hud::#{model_name}" if model_name
    h
  end
end
