class SetDefaultTraceIdInCps < ActiveRecord::Migration[4.2]
  def up
    Health::Cp.sender.first&.update(trace_id: 'OPENPATH00')
  end

  def down
  end
end
