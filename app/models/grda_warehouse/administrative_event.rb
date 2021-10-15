###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class AdministrativeEvent < GrdaWarehouseBase
    self.table_name = :administrative_events
    acts_as_paranoid

    belongs_to :user, optional: true
    validates_presence_of :date, :title
  end
end
