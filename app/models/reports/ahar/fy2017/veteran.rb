module Reports::Ahar::Fy2017
  class Veteran < Base
    def self.report_name
      'Veteran AHAR - FY 2017'
    end

    def report_type
      1
    end
  end
end