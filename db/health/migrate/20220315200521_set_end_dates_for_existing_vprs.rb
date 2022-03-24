class SetEndDatesForExistingVprs < ActiveRecord::Migration[6.1]
  def change
    HealthFlexibleService::Vpr.find_each do |vpr|
      vpr.update(end_date: vpr.planned_on + 6.months)
    end
  end
end
