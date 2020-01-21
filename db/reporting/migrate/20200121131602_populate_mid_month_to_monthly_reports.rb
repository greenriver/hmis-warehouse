class PopulateMidMonthToMonthlyReports < ActiveRecord::Migration[5.2]
  def up
    months = Reporting::MonthlyReports::Base.distinct.pluck(:month, :year)
    months.each do |month, year|
      Reporting::MonthlyReports::Base.where(month: month, year: year).update_all(mid_month: Date.new(year, month, 15))
    end
  end
end
