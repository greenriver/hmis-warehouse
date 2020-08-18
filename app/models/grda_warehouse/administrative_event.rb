###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class AdministrativeEvent < GrdaWarehouseBase
    self.table_name = :administrative_events
    acts_as_paranoid

    belongs_to :user
    validates_presence_of :date, :title
  end
end
