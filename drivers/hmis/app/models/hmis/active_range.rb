###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ActiveRange < Hmis::HmisBase
  self.table_name = :hmis_active_ranges
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :user, class_name: 'Hmis::User'

  def self.for_entity(entity)
    Hmis::ActiveRange.where(entity: entity).order(:updated_at).last
  end

  def active_on(date = Date.today)
    end_date.nil? || end_date > date
  end

  def active?
    active_on
  end
end
