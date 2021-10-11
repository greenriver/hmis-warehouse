###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Chronic < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :chronics, optional: true

    validates_presence_of :date

    scope :on_date, -> (date:) do
      where(date: date)
    end

    def self.most_recent_day
      if self.count > 0
        self.maximum(:date)
      else
        Date.current
      end
    end

    def self.sort_options
      [
        {title: 'Last name A-Z', column: 'LastName', direction: 'asc'},
        {title: 'Last name Z-A', column: 'LastName', direction: 'desc'},
        {title: 'First name A-Z', column: 'FirstName', direction: 'asc'},
        {title: 'First name Z-A', column: 'FirstName', direction: 'desc'},
        {title: 'Age (asc)', column: 'age', direction: 'asc'},
        {title: 'Age (desc)', column: 'age', direction: 'desc'},
        {title: 'Homeless since (asc)', column: 'homeless_since', direction: 'asc'},
        {title: 'Homeless since (desc)', column: 'homeless_since', direction: 'desc'},
        {title: 'Days in 3 yrs (asc)', column: 'days_in_last_three_years', direction: 'asc'},
        {title: 'Days in 3 yrs (desc)', column: 'days_in_last_three_years', direction: 'desc'},
        {title: 'Months in 3 yrs (asc)', column: 'months_in_last_three_years', direction: 'asc'},
        {title: 'Months in 3 yrs (desc)', column: 'months_in_last_three_years', direction: 'desc'},
      ]
    end
  end
end
