class ChangeHealthInstrumentRaceToJson < ActiveRecord::Migration[6.1]
  def change
    safety_assured { change_column :hca_assessments, :race, 'jsonb USING to_json(ARRAY[race])' }
    safety_assured { change_column :pctp_careplans, :race, 'jsonb USING to_json(ARRAY[race])' }
  end
end
