###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Base < GrdaWarehouseBase
    self.abstract_class = true
    self.lock_optimistically = false
    self.ignored_columns += [:lock_version]
    class_attribute :import_overrides

    scope :in_coc, ->(*) do
      current_scope
    end

    # This will return an equivalent record in the HMIS format
    # Note: because there is at least one ignored column on the Warehouse side
    # If you want the exact HMIS version, you will want the default behavior which
    # forces a reload of the object from the db.  If you just need the right shape,
    # you can skip the db call
    def as_hmis(force_reload: true)
      return self unless HmisEnforcement.hmis_enabled?

      hmis_class = "Hmis::Hud::#{self.class.name.demodulize}".constantize
      columns = self.class.column_names - hmis_class.ignored_columns
      hmis_entity = hmis_class.new(attributes.slice(*columns))
      return hmis_entity unless force_reload

      hmis_entity.reload
    end
  end
end
