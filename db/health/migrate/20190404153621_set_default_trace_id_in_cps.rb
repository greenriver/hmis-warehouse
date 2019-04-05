class SetDefaultTraceIdInCps < ActiveRecord::Migration
  def up
    Health::Cp.sender.first.update(trace_id: 'OPENPATH00')
  end

  def down
  end
end
