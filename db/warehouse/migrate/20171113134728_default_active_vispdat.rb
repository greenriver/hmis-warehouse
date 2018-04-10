class DefaultActiveVispdat < ActiveRecord::Migration
  def up
    vispdats = []
    GrdaWarehouse::Hud::Client.joins(:vispdats).
      merge(GrdaWarehouse::Vispdat::Base.completed).each do |client|
        vispdats << client.vispdats.completed.order(submitted_at: :desc).first.id
    end
    GrdaWarehouse::Vispdat::Base.where(id: vispdats).update_all(active: true)
    GrdaWarehouse::Vispdat::Base.completed.each do |vispdat|
      vispdat.update_columns({priority_score: vispdat.calculate_priority_score})
    end
  end
  
end
