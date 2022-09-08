require 'rails_helper'

RSpec.describe GrdaWarehouse::SystemCohorts::CurrentlyHomeless, type: :model do
  # Build out:
  # Client with
  # old PH: entry 2/1/2019, move-in 2/2/2019, exit 2/5/2019, destination: 20 - permanent
  # old ES entry/exit: entry 2/7/2019, exit 2/10/2019, destination: 2 - temporary
  # open ES entry/exit: entry 4/1/2021, exit 7/5/2021, destination: 99
  # PH enrollment 5/1/2021 with move-in 6/1/2021, exit 7/1/2021, destination: 99
  # ES NbN: entry 7/15/2021, services 7/15, 7/16, 8/5, 8/10, exit 12/1/2021, destination: 4 - temporary

  # process
  # walk each of the following dates with the following expectations
  # 3/30/2021 - no cohort clients
  # 4/1/2021 - client newly identified
  # 4/30/2021 - no change
  # 5/2/2021 - no change
  # 6/2/2021 - client housed
  # 6/30/2021 - no change
  # 7/2/2021 - returned from housed
  # 7/6/2021 - Inactive
  # 7/16/2021 - returned from inactive
  # 8/4/2021 - no change (not Inactive < 90 days, with open enrollment)
  # 8/6/2021 - no change (not returned from inactive < 90 days, with open enrollment)
  # 8/11/2021 - no change
  # 11/15/2021 - Inactive

  let(:config_setup) do
    config = GrdaWarehouse::Config.where(id: 1).first_or_create
    config.update(currently_homeless_cohort: true, enable_system_cohorts: true)
    GrdaWarehouse::ChEnrollment.maintain!
  end

  context 'When populating system cohorts' do
    before(:each) do
      warehouse = GrdaWarehouseBase.connection
      if Fixpoint.exists?(:system_cohorts_app) && Fixpoint.exists?(:system_cohorts_warehouse)
        cleanup_test_environment
        restore_fixpoint :system_cohorts_app
        restore_fixpoint :system_cohorts_warehouse, connection: warehouse
      else
        import_hmis_csv_fixture('spec/fixtures/files/system_cohorts')
        config_setup
        GrdaWarehouse::SystemCohorts::Base.update_all_system_cohorts(range: Date.new(2021, 3, 30)..Date.new(2021, 12, 2))
        store_fixpoint_unless_present :system_cohorts_app, exclude_tables: ['versions']
        store_fixpoint_unless_present :system_cohorts_warehouse, connection: warehouse, exclude_tables: ['spatial_ref_sys', 'versions']
      end
    end

    after(:all) do
      cleanup_test_environment
    end

    it 'Notes the client has been added' do
      date = Date.new(2020, 1, 1)..Date.new(2021, 4, 2)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Newly identified'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end

    it 'No new changes around beginning of PH enrollment' do
      date = Date.new(2021, 4, 30)..Date.new(2021, 5, 30)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      expect(changes.count).to eq(0)
    end

    it 'Notes the client housed' do
      date = Date.new(2021, 6, 1)..Date.new(2021, 6, 3)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Housed'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end

    it 'No new changes between PH move-in and exit' do
      date = Date.new(2021, 6, 3)..Date.new(2021, 6, 30)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      expect(changes.count).to eq(0)
    end

    it 'Notes the client returned from housing' do
      date = Date.new(2021, 7, 1)..Date.new(2021, 7, 3)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Returned from housing'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end

    it 'Notes the client Inactive' do
      date = Date.new(2021, 7, 5)..Date.new(2021, 7, 7)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Inactive'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end

    it 'No new changes' do
      date = Date.new(2021, 7, 8)..Date.new(2021, 7, 14)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      expect(changes.count).to eq(0)
    end

    it 'Notes the client returned from inactive' do
      date = Date.new(2021, 7, 15)..Date.new(2021, 7, 17)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Returned from inactive'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end

    it 'No new changes' do
      date = Date.new(2021, 7, 18)..Date.new(2021, 8, 2)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      expect(changes.count).to eq(0)
    end

    # it 'Notes the client Inactive' do
    #   date = Date.new(2021, 8, 3)..Date.new(2021, 8, 5)
    #   changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
    #   client = GrdaWarehouse::Hud::Client.destination.first
    #   expect(changes.map(&:reason)).to eq(['Inactive'])
    #   expect(changes.first.cohort_client.client_id).to eq(client.id)
    # end

    # it 'Notes the client returned from inactive' do
    #   date = Date.new(2021, 8, 6)..Date.new(2021, 8, 7)
    #   changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
    #   client = GrdaWarehouse::Hud::Client.destination.first
    #   expect(changes.map(&:reason)).to eq(['Returned from inactive'])
    #   expect(changes.first.cohort_client.client_id).to eq(client.id)
    # end

    # it 'No new changes' do
    #   date = Date.new(2021, 8, 8)..Date.new(2021, 8, 18)
    #   changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
    #   expect(changes.count).to eq(0)
    # end

    it 'Notes the client doesn\'t go Inactive - < 90 day window' do
      date = Date.new(2021, 8, 3)..Date.new(2021, 11, 5)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      expect(changes.count).to eq(0)
    end

    it 'Notes the client Inactive' do
      date = Date.new(2021, 11, 6)..Date.new(2021, 11, 15)
      changes = GrdaWarehouse::CohortClientChange.where(changed_at: date)
      client = GrdaWarehouse::Hud::Client.destination.first
      expect(changes.map(&:reason)).to eq(['Inactive'])
      expect(changes.first.cohort_client.client_id).to eq(client.id)
    end
  end
end
