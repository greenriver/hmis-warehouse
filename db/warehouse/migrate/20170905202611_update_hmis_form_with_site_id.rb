class UpdateHmisFormWithSiteId < ActiveRecord::Migration
  def up
    a_t = GrdaWarehouse::HMIS::Assessment.arel_table
    GrdaWarehouse::HMIS::Assessment.all.each do |assessment|
      GrdaWarehouse::HmisForm.where(data_source_id: assessment.data_source_id, assessment_id: assessment.assessment_id).update_all(site_id: assessment.site_id)
    end
  end
end
