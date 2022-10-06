class AddFilterDateSpan < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :filter_date_span_years, :integer, default: 1, null: false
  end
end
