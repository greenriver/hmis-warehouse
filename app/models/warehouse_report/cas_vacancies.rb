class WarehouseReport::CasVacancies < OpenStruct
  include ArelHelper

  attr_accessor :start_date
  attr_accessor :end_date

end