class AddEnrollmentDisenrollmentToScheduledDocuments < ActiveRecord::Migration[5.2]
  def change
    change_table :scheduled_documents do |t|
      t.integer :acos, array: true, default: []
      t.integer :scheduled_day
    end
  end
end
