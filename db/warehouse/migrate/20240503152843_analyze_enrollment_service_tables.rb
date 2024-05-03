class AnalyzeEnrollmentServiceTables < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      [
        'Enrollment',
        'Services',
        'CustomServices',
      ].each do |table|
        execute(%(VACUUM ANALYZE "#{table}"))
      end
    end
  end

  def down
    # no-op
  end
end
