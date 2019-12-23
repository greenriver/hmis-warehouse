class MoveGeographyOverrides < ActiveRecord::Migration
  def up
    [:geography_type_override, :geocode_override].each do |col|
      GrdaWarehouse::Hud::Geography.where.not(col => nil).each do |geo|
        geo.project.project_cocs.where(col => nil, CoCCode: geo.CoCCode).update_all(col => geo[col])
      end
    end
  end
end
