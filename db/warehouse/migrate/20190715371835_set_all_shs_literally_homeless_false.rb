class SetAllShsLiterallyHomelessFalse < ActiveRecord::Migration
  def up
    # DO this after deployment
    # years = (1900..2020).each do |year|
    #    range = Date.new(year, 01, 01) .. Date.new(year, 12, 31)
    #    puts "Updating #{range.inspect}"
    #    GrdaWarehouse::ServiceHistoryService.where(date: range).update_all(literally_homeless: false)
    # end

    change_column_default :service_history_services, :literally_homeless, false
  end
end
