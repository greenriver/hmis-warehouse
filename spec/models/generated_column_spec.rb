require 'rails_helper'

# This just confirms that the generated columns and relations that use them are working
RSpec.describe GrdaWarehouse::Hud::Enrollment, type: :model do
  include ActiveJob::TestHelper

  let!(:warehouse_ds) { create :destination_data_source }
  let!(:source_ds) { create :source_data_source }
  let!(:client) { create :grda_warehouse_hud_client, data_source_id: warehouse_ds.id }
  let!(:source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: source_ds.id,
      PersonalID: client.PersonalID,
    )
  end
  let!(:warehouse_client) do
    create(
      :warehouse_client,
      destination: client,
      source: source_client,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:project) do
    create(
      :grda_warehouse_hud_project,
      ProjectType: 1,
      data_source_id: source_ds.id,
    )
  end
  let!(:source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a',
      ProjectID: project.ProjectID,
      EntryDate: Date.new(2014, 4, 1),
      DisablingCondition: 1,
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
    )
  end
  let!(:source_disability) do
    create(
      :hud_disability,
      EnrollmentID: source_enrollment.EnrollmentID,
      InformationDate: Date.new(2014, 4, 1),
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
      DisabilityType: 5,
      DisabilityResponse: 1,
      IndefiniteAndImpairs: 1,
    )
  end

  describe 'Confirm relations that use generated columns work' do
    it 'client related' do
      aggregate_failures do
        expect(client.source_enrollments.count).to eq(1)
        expect(client.source_disabilities.count).to eq(1)
        en = client.source_enrollments.first
        expect(en.disabilities.count).to eq(1)
        expect(en.client_slug).not_to be_empty
        expect(en.enrollment_slug).not_to be_empty
        expect(en.disabilities.first.enrollment_slug).not_to be_empty
        expect(en.enrollment_slug).to eq(en.disabilities.first.enrollment_slug)
      end
    end
    # At the time of this writing, composite keys in rails 7 with a preload on a has many through
    # where that is not the only preload, are firing an extra query that is unscoped and returns
    # the entire table (in the preload only)  Manually confirmed that adds a 7th query.
    # This is a canary to confirm if the behavior changes back
    it 'preload does not run extra queries' do
      # 1. Client load
      # 2. Warehouse client load
      # 3. Source client load
      # 4. Source Enrollment preload
      # 5. Source disabilities preload
      # 6. Source Enrollment Disabilities preload
      expect do
        GrdaWarehouse::Hud::Client.where(id: client.id).
          preload(:source_disabilities, source_enrollments: :disabilities).to_a
      end.to make_database_queries(count: 6)
    end
    # At the time of this writing, composite keys in rails 7 with a preload on a has many through
    # where that is not the only preload, is converting the usual prepared statement into a fully
    # written out SQL statement (`where data_source_id = $1` is being written as `where data_source_id = 100`).
    # This is a canary to confirm all queries in the batch include at least one $1.
    # At the time of this writing, using composite keys returns 3 matches
    it 'does not make any queries that do not contain at least one $' do
      # All six should include a $1
      expect do
        GrdaWarehouse::Hud::Client.where(id: client.id).
          preload(:source_disabilities, source_enrollments: :disabilities).to_a
      end.to make_database_queries(count: 6, matching: '$1')
    end
  end
end
