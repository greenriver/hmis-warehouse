class CreateSyntheticYouthEducationStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :synthetic_youth_education_statuses do |t|
      t.references :enrollment
      t.references :client
      t.string :type
      t.references :source, polymorphic: true

      t.string :hud_youth_education_status_youth_education_status_id

      t.timestamps
    end

    add_column :YouthEducationStatus, :synthetic, :boolean, default: false
  end
end
