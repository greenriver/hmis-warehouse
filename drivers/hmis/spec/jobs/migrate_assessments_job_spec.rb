###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MigrateAssessmentsJob, type: :model do
  context 'builds simple assesssment' do
    let!(:ds1) { create(:hmis_data_source) }
    let!(:u1) { create :hmis_hud_user, data_source: ds1 }
    let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:ib1) { create :hmis_income_benefit, data_source: ds1, enrollment: e1, client: c1 }
    let!(:hd1) { create :hmis_health_and_dv, data_source: ds1, enrollment: e1, client: c1 }
    before { Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id) }

    it 'creates new assessments correctly' do
      expect(e1.custom_assessments.count).to eq(1)
      assessment = e1.custom_assessments.first
      expect(assessment.income_benefit).to eq(ib1)
      expect(assessment.health_and_dv).to eq(hd1)

      records = [ib1, hd1]
      expect(records.map(&:user)).to include(assessment.user)
    end
  end
end
