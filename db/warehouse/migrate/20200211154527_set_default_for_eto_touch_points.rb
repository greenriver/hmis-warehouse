class SetDefaultForEtoTouchPoints < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::HMIS::Assessment.where(name: 'Boston CoC Coordinated Entry Assessment').update_all(rrh_assessment: true)
    GrdaWarehouse::HMIS::Assessment.where(name: 'Triage Assessment').update_all(triage_assessment: true)
    GrdaWarehouse::HMIS::Assessment.where(name: 'VI-SPDAT v2').update_all(vispdat: true)
    GrdaWarehouse::HMIS::Assessment.where(name: 'Self-Sufficiency Matrix').update_all(ssm: true)
    GrdaWarehouse::HMIS::Assessment.where(name: ['SDH Case Management Note', 'Case Management Daily Note']).update_all(health_case_note: true)
    GrdaWarehouse::HMIS::Assessment.where(name: 'Case Management Daily Note').update_all(health_has_qualifying_activities: true)
    GrdaWarehouse::HMIS::Assessment.where(name: 'HUD Assessment (Entry/Update/Annual/Exit)').update_all(hud_assessment: true)
  end
end
