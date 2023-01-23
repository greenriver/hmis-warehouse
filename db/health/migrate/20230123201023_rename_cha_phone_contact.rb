class RenameChaPhoneContact < ActiveRecord::Migration[6.1]
  def up
    Health::ComprehensiveHealthAssessment.where(collection_method: :phone).update_all(collection_method: :phone_call)
  end
end
