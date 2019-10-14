class MigrateDaysSinceCasMatch < ActiveRecord::Migration
  def change
    GrdaWarehouse::WarehouseClientsProcessed.where.not(days_since_cas_match: nil).find_each do |wcp|
      wcp.update(last_cas_match_date: Time.at(wcp.days_since_cas_match))
    end
  end
end
