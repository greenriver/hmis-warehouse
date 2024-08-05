require 'rails_helper'

RSpec.describe GrdaWarehouse::SystemCohorts::CurrentlyHomeless, type: :model do
  let!(:currently_homeless_cohort) { create :currently_homeless_cohort }
  let!(:new_client) { create :hud_client }
  let!(:housed_client) { create :hud_client }

  describe 'finds current clients' do
    date = '2020-01-01'.to_date
    let!(:enrollment_1) { create :she_entry, client_id: new_client.id, project_type: 1, date: date, first_date_in_program: date }
    let!(:enrollment_2) { create :she_entry, client_id: housed_client.id, project_type: 1, date: date, first_date_in_program: date }
    let!(:enrollment_3) { create :she_entry, client_id: housed_client.id, project_type: 3, date: date - 1.day, first_date_in_program: date - 1.day, move_in_date: date - 1.day }

    let!(:service_1) { create :service_history_service, client_id: new_client.id, service_history_enrollment_id: enrollment_1.id, record_type: 'service', date: date }

    it 'finds the client' do
      travel_to('2020-01-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
      end
    end

    it "doesn't find the client when it is inactive" do
      travel_to('2020-04-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
      end
    end

    it 'removes the client when it becomes inactive' do
      travel_to('2020-01-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
      end

      travel_to('2020-04-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
      end
    end

    it 'removes the client when they exit' do
      travel_to('2020-02-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(1)

        enrollment_1.update(last_date_in_program: '2020-01-31'.to_date, destination: HudUtility2024.temporary_destinations.first)
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
      end
    end
  end

  describe 'removes the client when it is housed' do
    first_date = '2020-01-01'.to_date
    let!(:enrollment_1) { create :she_entry, client_id: new_client.id, project_type: 1, date: first_date, first_date_in_program: first_date }

    let!(:service_1) { create :service_history_service, client_id: new_client.id, service_history_enrollment_id: enrollment_1.id, record_type: 'service', date: first_date }

    it 'first it finds the client' do
      travel_to('2020-01-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
      end
    end

    context 'then with the housed enrollment' do
      second_date = '2020-01-31'.to_date
      let!(:housed_enrollment) { create :she_entry, client_id: new_client.id, project_type: 3, date: second_date, first_date_in_program: second_date, move_in_date: second_date }

      it 'removes the client' do
        travel_to('2020-02-01'.to_date) do
          currently_homeless_cohort.sync
          expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
        end
      end
    end
  end

  describe 'looking at CE enrollments' do
    date = '2019-12-01'.to_date
    let!(:ds) { create :data_source_fixed_id }
    let!(:project) { create :hud_project, data_source_id: ds.id }
    let!(:ce_only_client) { create :hud_client, data_source_id: ds.id }
    let!(:ce_source_enrollment) { create :grda_warehouse_hud_enrollment, EntryDate: date, client: ce_only_client, data_source_id: ds.id, ProjectID: project.ProjectID }
    let!(:she_ce) { create :she_entry, client_id: ce_only_client.id, project_type: 14, date: date, first_date_in_program: date, enrollment_group_id: ce_source_enrollment.EnrollmentID, project_id: ce_source_enrollment.ProjectID, data_source_id: ce_source_enrollment.data_source_id }
    let!(:ce_service) { create :service_history_service, client_id: ce_only_client.id, service_history_enrollment_id: she_ce.id, record_type: 'service', date: date }

    it "doesn't find the client" do
      travel_to('2020-01-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
      end
    end

    describe 'with CLS' do
      let!(:homeless_cls) { create :hud_current_living_situation, InformationDate: date, CurrentLivingSituation: HudUtility2024.homeless_situations(as: :current).first, EnrollmentID: ce_source_enrollment.EnrollmentID, PersonalID: ce_source_enrollment.PersonalID, data_source_id: ds.id }
      it 'finds the client' do
        travel_to('2020-01-01'.to_date) do
          currently_homeless_cohort.sync
          expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
        end
      end

      describe 'with additional CLS' do
        let!(:homeless_cls) { create :hud_current_living_situation, InformationDate: date + 1.days, CurrentLivingSituation: HudUtility2024.other_situations(as: :current).first, EnrollmentID: ce_source_enrollment.EnrollmentID, PersonalID: ce_source_enrollment.PersonalID, data_source_id: ds.id }
        it 'no longer finds the client' do
          travel_to('2020-01-01'.to_date) do
            currently_homeless_cohort.sync
            expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
          end
        end
      end

      describe 'with additional open enrollment in any non-homeless project type' do
        let!(:she_hp) { create :she_entry, client_id: ce_only_client.id, project_type: 12, date: date - 1.days, first_date_in_program: date - 1.days }
        it 'no longer finds the client' do
          travel_to('2020-01-01'.to_date) do
            currently_homeless_cohort.sync
            expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
          end
        end
      end

      describe 'with additional closed enrollment' do
        let!(:she_hp) { create :she_entry, client_id: ce_only_client.id, project_type: 12, date: date - 5.days, first_date_in_program: date - 5.days, last_date_in_program: date - 1.days }
        it 'finds the client' do
          travel_to('2020-01-01'.to_date) do
            currently_homeless_cohort.sync
            expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
          end
        end
      end
    end
  end
end
