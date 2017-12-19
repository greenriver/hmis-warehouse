# provides validation for date ranges
module Filters
  class DateRangeWithSubPopulation < DateRange
    attribute :sub_population, Symbol, default: :all_clients

    validates_presence_of :start, :end, :sub_population

  
  end
end
