class CreateHealthQaFactoryFactories < ActiveRecord::Migration[6.1]
  def change
    create_table :health_qa_factory_factories do |t|
      t.references :patient
      t.references :careplan

      t.references :hrsn_screening_qa, references: :qualifying_activities
      t.references :ca_development_qa, references: :qualifying_activities
      t.references :ca_completed_qa, references: :qualifying_activities
      t.references :careplan_development_qa, references: :qualifying_activities
      t.references :careplan_completed_qa, references: :qualifying_activities

      t.timestamps
    end
  end
end
