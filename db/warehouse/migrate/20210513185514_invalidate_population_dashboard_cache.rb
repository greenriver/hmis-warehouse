class InvalidatePopulationDashboardCache < ActiveRecord::Migration[5.2]
  def up
    Reporting::MonthlyReports::Base.available_types.each_key do |k|
      Reporting::MonthlyReports::Base.class_for(k).new.send(:maintain_month_range_cache)
    end
  end
end
