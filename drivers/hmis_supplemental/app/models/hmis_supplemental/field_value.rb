###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisSupplemental
  class FieldValue < GrdaWarehouseBase
    self.table_name = 'hmis_supplemental_field_values'
    belongs_to :data_set, class_name: 'HmisSupplemental::DataSet'
    serialize :data, type: Hash

    # use a single key rather than a polymorphic association
    # * keeps class names out of the db
    # * simplifies uniqueness constraint
    # * uses method rather than an association to avoid dependent-destroy behavior
    def self.for_owner(entity)
      case entity
      when GrdaWarehouse::Hud::Client
        owner_key = "client/#{entity.personal_id}"
      when GrdaWarehouse::Hud::Enrollment
        owner_key = "enrollment/#{entity.enrollment_id}"
      end
      where(data_source_id: entity.data_source_id, owner_key: owner_key)
    end
  end
end
