class RecreateReportViews < ActiveRecord::Migration
  def up
    load 'db/warehouse/migrate/20170928185422_recreate_views_with_incorrect_primary_keys.rb'
    RecreateViewsWithIncorrectPrimaryKeys.new.create_order
  end
end
