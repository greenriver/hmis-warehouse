# frozen_string_literal: true

class SetReplicaForAnalyticsAppUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    safety_assured do
      execute('ALTER TABLE analytics.app_users REPLICA IDENTITY FULL')
      result = execute('SELECT relreplident FROM pg_class WHERE oid = \'analytics.app_users\'::regclass')
      puts "Current replica identity: #{result.first['relreplident']}"
    end
  end

  def down
    safety_assured do
      execute('ALTER TABLE analytics.app_users REPLICA IDENTITY DEFAULT')
    end
  end
end
