class CreateSystemColors < ActiveRecord::Migration[6.1]
  def change
    create_table :system_colors do |t|
      t.string :slug, null: false
      t.string :background_color, null: false
      t.string :foreground_color

      t.timestamps
    end
  end
end
