class CreateAnalyticsSchema < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute 'CREATE SCHEMA analytics'
    end
  end

  def down
    safety_assured do
      execute 'DROP SCHEMA analytics CASCADE'
    end
  end
end
