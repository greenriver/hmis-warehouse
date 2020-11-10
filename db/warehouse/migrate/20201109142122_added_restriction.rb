class AddedRestriction < ActiveRecord::Migration[5.2]
  def change
    add_reference :health_emergency_uploaded_tests, :ama_restriction
  end
end
