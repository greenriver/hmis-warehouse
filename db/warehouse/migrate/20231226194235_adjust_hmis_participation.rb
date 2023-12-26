class AdjustHmisParticipation < ActiveRecord::Migration[6.1]
  def up
    # The spec doesn't allow nil or 99, which we had incorrectly copied from the 2022 fields (which did allow them)
    GrdaWarehouse::Hud::HmisParticipation.
      where(GrdaWarehouse::Hud::HmisParticipation.arel_table[:HMISParticipationID].matches('GR-%', nil, true)).
      where(HMISParticipationType: [nil, 99]).
      update_all(HMISParticipationType: 0)
  end
end
