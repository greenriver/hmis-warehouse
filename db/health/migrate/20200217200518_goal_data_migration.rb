class GoalDataMigration < ActiveRecord::Migration[5.2]
  def up
    Health::Goal::Hpc.find_each do |goal|
      interventions = "|#{goal.intervention&.gsub(/\n+/, '|')}"&.split(/\|\d\./)
      interventions.map(&:strip).map(&:presence).compact.each_with_index do |data, i|
        goal["action_step_#{i}"] = data.gsub(/\|/, "\n")
      end

      timeframes = "|#{goal.timeframe&.gsub(/\n+/, '|')}"&.split(/\|\d\./)
      timeframes.map(&:strip).map(&:presence).compact.each_with_index do |data, i|
        goal["timeframe_#{i}"] = data.gsub(/\|/, "\n")
      end
      goal.save
    end
  end
end
