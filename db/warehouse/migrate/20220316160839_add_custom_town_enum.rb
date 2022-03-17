class AddCustomTownEnum < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      ALTER TYPE public.census_levels ADD VALUE 'CUSTOMTOWN';
    SQL
  end
end
