class HomelessDefaultRecalculation < ActiveRecord::Migration
  def up
    system 'rake grda_warehouse:force_rebuild_for_homeless_enrollments'
  end
end
