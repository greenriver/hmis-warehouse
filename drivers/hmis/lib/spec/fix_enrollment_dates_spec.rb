#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../hmis_data_cleanup/fix_enrollment_dates_20240416'

RSpec.describe FixEnrollmentDates20240416 do
  let!(:ds1) { create(:hmis_data_source) }
  let!(:u1) { create :hmis_hud_user, data_source: ds1, user_email: 'test@example.com' }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Emery', last_name: 'Staines' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Anna', last_name: 'Wetherell' }

  describe 'for normal projects' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: Date.today - 1.day, exit_date: Date.today - 1.day }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, entry_date: Date.today - 2.days, exit_date: Date.today - 1.day }

    it 'should correctly modify the exit dates of enrollments' do
      FixEnrollmentDates20240416.new(special_treatment_project_id: p2.project_id).perform

      e1.reload
      expect(e1.exit_date).to eq(Date.today), 'it should add one day to exit date when entry = exit'
      e2.reload
      expect(e2.exit_date).to eq(Date.today - 1.day), 'it should not change when entry < exit'
    end
  end

  describe 'for special projects' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, entry_date: Date.new(2023, 1, 1), exit_date: Date.new(2020, 2, 1) }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c2, entry_date: Date.new(2023, 2, 1), exit_date: Date.new(2023, 1, 1) }
    let!(:bn1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 200, date_provided: Date.new(2020, 1, 1) }
    let!(:bn2) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e2, user: u1, record_type: 200, date_provided: Date.new(2023, 1, 1) }
    let!(:non_bn_service) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: Date.new(2020, 1, 1) }

    it 'should correctly modify the exit dates of enrollments' do
      FixEnrollmentDates20240416.new(special_treatment_project_id: p2.project_id).perform

      e1.reload
      expect(e1.exit_date).to eq(Date.new(2023, 2, 1)), 'should keep date the same but make the year 2023 if year is 2020 and entry > exit'
      e2.reload
      expect(e2.exit_date).to eq(Date.new(2023, 1, 1)), 'should not change if year is not 2020, even when when entry > exit'
    end

    it 'should correctly modify service dates' do
      FixEnrollmentDates20240416.new(special_treatment_project_id: p2.project_id).perform

      bn1.reload
      expect(bn1.date_provided).to eq(Date.new(2023, 1, 1)), 'should keep date the same but make the year 2023 if year is 2020'
      bn2.reload
      expect(bn2.date_provided).to eq(Date.new(2023, 1, 1)), 'should not change if year is not 2020'
      non_bn_service.reload
      expect(non_bn_service.date_provided).to eq(Date.new(2020, 1, 1)), 'should not change if service is not bed night'
    end
  end

  describe 'for non-residential projects' do
    # 11 is day shelter - non-residential
    let!(:p3) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 11 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p3, client: c1, entry_date: Date.new(2023, 1, 1), exit_date: Date.new(2023, 1, 1) }

    it 'should not make any changes' do
      FixEnrollmentDates20240416.new(special_treatment_project_id: p2.project_id).perform

      e3.reload
      expect(e3.exit_date).to eq(Date.new(2023, 1, 1)), 'should be unchanged'
    end
  end
end
