module Reports::Ahar::Fy2016
  class Veteran < Base
    def self.report_name
      'Veteran AHAR - FY 2016'
    end

    def report_type
      1
    end
  end
end