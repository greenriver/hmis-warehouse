require 'rails_helper'

RSpec.describe GrdaWarehouse::SystemCohorts::CurrentlyHomeless, type: :model do
  let!(:currently_homeless_cohort) { create :currently_homeless_cohort }
  let!(:new_client) { create :hud_client }
  let!(:housed_client) { create :hud_client }

  describe 'finds current clients' do
    date = '2020-01-01'.to_date
    let!(:enrollment_1) { create :she_entry, client_id: new_client.id, computed_project_type: 1, date: date, first_date_in_program: date }
    let!(:enrollment_2) { create :she_entry, client_id: housed_client.id, computed_project_type: 1, date: date, first_date_in_program: date }
    let!(:enrollment_3) { create :she_entry, client_id: housed_client.id, computed_project_type: 3, date: date - 1.day, first_date_in_program: date - 1.day, move_in_date: date - 1.day }

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

        enrollment_1.update(last_date_in_program: '2020-01-31'.to_date, destination: HUD.temporary_destinations.first)
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
      end
    end
  end

  describe 'removes the client when it is housed' do
    first_date = '2020-01-01'.to_date
    let!(:enrollment_1) { create :she_entry, client_id: new_client.id, computed_project_type: 1, date: first_date, first_date_in_program: first_date }

    let!(:service_1) { create :service_history_service, client_id: new_client.id, service_history_enrollment_id: enrollment_1.id, record_type: 'service', date: first_date }

    it 'first it finds the client' do
      travel_to('2020-01-01'.to_date) do
        currently_homeless_cohort.sync
        expect(currently_homeless_cohort.cohort_clients.count).to eq(1)
      end
    end

    context 'then with the housed enrollment' do
      second_date = '2020-01-31'.to_date
      let!(:housed_enrollment) { create :she_entry, client_id: new_client.id, computed_project_type: 3, date: second_date, first_date_in_program: second_date, move_in_date: second_date }

      it 'removes the client' do
        travel_to('2020-02-01'.to_date) do
          currently_homeless_cohort.sync
          expect(currently_homeless_cohort.cohort_clients.count).to eq(0)
        end
      end
    end
  end
end
