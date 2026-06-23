###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Export::Scopes do
  let(:source_ds) { create(:source_data_source) }
  let(:dest_ds)   { create(:destination_data_source) }
  let(:user)      { create(:user) }
  let!(:cde_definition) do
    create(
      :hud_custom_data_element_definition,
      key: ClientExternalDataSharing::EXTERNAL_DATA_SHARING_CDE_KEY,
      owner_type: 'GrdaWarehouse::Hud::Client',
      field_type: 'boolean',
      data_source_id: dest_ds.id,
    )
  end

  before { GrdaWarehouse::Hud::Client.instance_variable_set(:@external_data_sharing_cde_definition, nil) }

  def make_destination(source_client, warehouse_created_at: 30.days.ago)
    dest = GrdaWarehouse::Hud::Client.create!(
      source_client.attributes.except('id').merge('data_source_id' => dest_ds.id),
    )
    wc = GrdaWarehouse::WarehouseClient.create!(
      id_in_source: source_client.PersonalID,
      data_source_id: source_client.data_source_id,
      source_id: source_client.id,
      destination_id: dest.id,
    )
    wc.update_column(:created_at, warehouse_created_at)
    dest
  end

  def build_exporter(project_ids, options: {})
    HmisCsvTwentyTwentySix::Exporter::Base.new(
      user_id: user.id,
      start_date: 1.year.ago.to_date,
      end_date: Date.current,
      projects: project_ids,
      options: options,
    )
  end

  describe '#client_scope external data sharing restrictions' do
    let(:project)       { create(:hud_project, data_source: source_ds) }
    let(:source_client) { create(:hud_client, data_source: source_ds) }
    let!(:dest_client)  { make_destination(source_client) }
    let!(:enrollment) do
      create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: source_client.PersonalID)
    end
    let(:exporter) { build_exporter([project.id]) }

    context 'when config is disabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(false) }

      it 'includes an excluded client in client_scope' do
        dest_client.set_external_data_sharing_exclusion!(value: true)
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end
    end

    context 'when config is enabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

      it 'excludes a client flagged via CDE' do
        dest_client.set_external_data_sharing_exclusion!(value: true)
        expect(exporter.client_scope.pluck(:id)).not_to include(dest_client.id)
      end

      it 'excludes a client whose warehouse_client was created less than 1 week ago' do
        new_source = create(:hud_client, data_source: source_ds)
        create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        embargoed_dest = make_destination(new_source, warehouse_created_at: 2.days.ago)
        expect(exporter.client_scope.pluck(:id)).not_to include(embargoed_dest.id)
      end

      it 'includes a non-excluded client whose warehouse_client is older than 1 week' do
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end

      it 'includes a client whose exclusion CDE was set to false (uncheck scenario)' do
        # Set true then false so a CDE row exists with value_boolean: false.
        # A client with no row at all would also pass — this ensures the value_boolean: true
        # filter in externally_excluded_client_ids is load-bearing.
        dest_client.set_external_data_sharing_exclusion!(value: true)
        dest_client.set_external_data_sharing_exclusion!(value: false)
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end

      it 'includes a client whose warehouse_client is exactly 8 days old (outside embargo window)' do
        new_source = create(:hud_client, data_source: source_ds)
        create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        non_embargoed_dest = make_destination(new_source, warehouse_created_at: 8.days.ago)
        expect(exporter.client_scope.pluck(:id)).to include(non_embargoed_dest.id)
      end
    end

    context 'when CDE definition does not exist' do
      before do
        # Simulate the seed task not having run yet.
        cde_definition.destroy
        # Config must be stubbed to true so the code reaches the definition lookup.
        # Without this, the config gate returns [] early and the definition-absent
        # guard is never exercised.
        allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true)
      end

      it 'includes all clients without error' do
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end
    end
  end

  describe '#enrollment_scope external data sharing restrictions' do
    let(:project)       { create(:hud_project, data_source: source_ds) }
    let(:source_client) { create(:hud_client, data_source: source_ds) }
    let!(:dest_client)  { make_destination(source_client) }
    let!(:enrollment) do
      create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: source_client.PersonalID)
    end
    let(:exporter) { build_exporter([project.id]) }

    context 'when config is disabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(false) }

      it 'includes enrollments for an excluded client' do
        dest_client.set_external_data_sharing_exclusion!(value: true)
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end
    end

    context 'when config is enabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

      it 'excludes enrollments for a client flagged via CDE' do
        dest_client.set_external_data_sharing_exclusion!(value: true)
        expect(exporter.enrollment_scope.pluck(:id)).not_to include(enrollment.id)
      end

      it 'excludes enrollments for a client whose warehouse_client was created less than 1 week ago' do
        new_source = create(:hud_client, data_source: source_ds)
        new_enrollment = create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        make_destination(new_source, warehouse_created_at: 2.days.ago)
        expect(exporter.enrollment_scope.pluck(:id)).not_to include(new_enrollment.id)
      end

      it 'includes enrollments for a non-excluded client whose warehouse_client is older than 1 week' do
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end

      it 'includes enrollments for a client whose exclusion CDE was set to false (uncheck scenario)' do
        # Set true then false so a CDE row exists with value_boolean: false.
        # A client with no row at all would also pass — this ensures the value_boolean: true
        # filter in externally_excluded_client_ids is load-bearing.
        dest_client.set_external_data_sharing_exclusion!(value: true)
        dest_client.set_external_data_sharing_exclusion!(value: false)
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end

      it 'includes enrollments for a client whose warehouse_client is exactly 8 days old (outside embargo window)' do
        new_source = create(:hud_client, data_source: source_ds)
        new_enrollment = create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        make_destination(new_source, warehouse_created_at: 8.days.ago)
        expect(exporter.enrollment_scope.pluck(:id)).to include(new_enrollment.id)
      end
    end

    context 'when CDE definition does not exist' do
      before do
        # Simulate the seed task not having run yet.
        cde_definition.destroy
        # Config must be stubbed to true so the code reaches the definition lookup.
        # Without this, the config gate returns [] early and the definition-absent
        # guard is never exercised.
        allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true)
      end

      it 'includes all enrollments without error' do
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end
    end
  end
end
