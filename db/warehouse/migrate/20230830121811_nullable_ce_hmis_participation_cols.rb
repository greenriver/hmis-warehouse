class NullableCeHmisParticipationCols < ActiveRecord::Migration[6.1]
  def change
    # change_column_null :HMISParticipation, :HMISParticipationType, true
    change_column_null :HMISParticipation, :HMISParticipationStatusStartDate, true
    change_column_null :HMISParticipation, :UserID, true
    change_column_null :HMISParticipation, :ExportID, true

    # change_column_null :CEParticipation, :AccessPoint, true
    # change_column_null :CEParticipation, :CEParticipationStatusStartDate, true
    change_column_null :CEParticipation, :UserID, true
    change_column_null :CEParticipation, :ExportID, true
  end
end
