###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe VeteransSubPop::Reporting::MonthlyReports::Veterans, type: :model do
  let(:report) { build :veteran_dashboard, date_range: '2015-01-01'.to_date..'2017-01-01'.to_date }
  let!(:data_source) { create :data_source_fixed_id }
  let!(:veteran) { create :hud_client, VeteranStatus: 1, data_source_id: 1 }
  let!(:non_vet) { create :hud_client, VeteranStatus: 99, data_source_id: 1 }
  let!(:organization) { create :hud_organization, data_source_id: 1 }
  let!(:project) { create :hud_project, data_source_id: 1, OrganizationID: organization.OrganizationID }

  # start
  let!(:she_1) { create :she_entry, client_id: veteran.id, computed_project_type: 1, date: '2015-01-05'.to_date, first_date_in_program: '2015-01-05'.to_date, last_date_in_program: '2015-03-10'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # 5 day break
  let!(:she_2) { create :she_entry, client_id: veteran.id, computed_project_type: 2, date: '2015-03-15'.to_date, first_date_in_program: '2015-03-15'.to_date, last_date_in_program: '2015-04-02'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # no break, entry prior to previous exit
  let!(:she_3) { create :she_entry, client_id: veteran.id, computed_project_type: 4, date: '2015-04-01'.to_date, first_date_in_program: '2015-04-01'.to_date, last_date_in_program: '2015-04-05'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # no break, same entry as previous exit
  let!(:she_4) { create :she_entry, client_id: veteran.id, computed_project_type: 1, date: '2015-04-05'.to_date, first_date_in_program: '2015-04-05'.to_date, last_date_in_program: '2015-04-13'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # 90 day break
  let!(:she_5) { create :she_entry, client_id: veteran.id, computed_project_type: 4, date: '2015-07-12'.to_date, first_date_in_program: '2015-07-12'.to_date, last_date_in_program: '2015-07-22'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # 10 day break
  let!(:she_6) { create :she_entry, client_id: veteran.id, computed_project_type: 1, date: '2015-08-01'.to_date, first_date_in_program: '2015-08-01'.to_date, last_date_in_program: nil, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # no break, prior enrollment doesn't have an exit
  let!(:she_7) { create :she_entry, client_id: veteran.id, computed_project_type: 1, date: '2015-09-01'.to_date, first_date_in_program: '2015-09-01'.to_date, last_date_in_program: '2015-09-10'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # no break, prior enrollment doesn't have an exit
  let!(:she_8) { create :she_entry, client_id: veteran.id, computed_project_type: 8, date: '2015-09-21'.to_date, first_date_in_program: '2015-09-21'.to_date, last_date_in_program: '2015-12-21'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }
  # not included, non-vet
  let!(:she_8) { create :she_entry, client_id: non_vet.id, computed_project_type: 8, date: '2015-09-21'.to_date, first_date_in_program: '2015-09-21'.to_date, last_date_in_program: '2015-12-21'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }

  describe 'setting enrollments' do
    before :each do
      ids = [veteran.id, non_vet.id]
      @enrollments_by_client = report.enrollments_by_client ids
      @months_for_vet = @enrollments_by_client[veteran.id]
    end
    it 'returns 1 client' do
      expect(@enrollments_by_client.keys.count).to eq 1
    end
    it 'client has 7 unique months' do
      expect(@months_for_vet.select(&:entered).count).to eq 7
    end
    it 'client was enrolled for 23 months' do
      expect(@months_for_vet.map { |m| [m.year, m.month] }.uniq.count).to eq 23
    end
    describe 'setting prior enrollment values' do
      before :each do
        report.apply_prior_enrollments(@enrollments_by_client)
      end
      it 'days_since_last_exit is set on 3 monthly records' do
        expect(@months_for_vet.select { |m| m.days_since_last_exit.present? }.count).to eq 3
      end
      it 'sets the expected values' do
        expect(@months_for_vet.map(&:days_since_last_exit).compact.sort).to eq [5, 10, 90]
      end
      it 'prior_exit_project_type is set on 3 monthly records' do
        expect(@months_for_vet.select { |m| m.prior_exit_project_type.present? }.count).to eq 3
      end
      it 'sets the expected values' do
        expect(@months_for_vet.map(&:prior_exit_project_type).compact.sort).to eq [1, 1, 4]
      end
    end
  end
end
