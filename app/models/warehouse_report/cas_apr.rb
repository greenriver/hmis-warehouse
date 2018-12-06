class WarehouseReport::CasApr < OpenStruct
  include ArelHelper

  attr_accessor :start_date
  attr_accessor :end_date

  def total_households
    unique_households.count
  end

  def total_families
    unique_households.family
  end

  def unique_households
    GrdaWarehouse::CasAvailablity.available_between(start_date: self.start_date, end_date: self.end_date).distinct.select(:client_id)
  end

end