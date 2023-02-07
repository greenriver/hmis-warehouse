###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ActiveRange < Hmis::HmisBase
  self.table_name = :hmis_active_ranges
  belongs_to :entity, polymorphic: true, optional: true

  def self.for_entity(entity)
    Hmis::ActiveRange.where(entity: entity).order(:updated_at).last
  end
end
