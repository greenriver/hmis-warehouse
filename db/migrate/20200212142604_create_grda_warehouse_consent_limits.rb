class CreateGrdaWarehouseConsentLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :consent_limits do |t|
      t.string :name, null: false, index: true
      t.text :description
      t.string :color
      t.datetime :deleted_at

      t.timestamps
    end

    create_table :agencies_consent_limits, id: false do |t|
      t.belongs_to :consent_limit, null: false
      t.belongs_to :agency, null: false
    end
  end
end
