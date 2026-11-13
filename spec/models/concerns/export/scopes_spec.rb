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
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end
    end

    context 'when config is enabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

      it 'excludes a client flagged for exclusion' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(exporter.client_scope.pluck(:id)).not_to include(dest_client.id)
      end

      it 'excludes a client whose warehouse_client was created less than 1 week ago, without affecting older clients' do
        new_source = create(:hud_client, data_source: source_ds)
        create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        embargoed_dest = make_destination(new_source, warehouse_created_at: 2.days.ago)
        ids = exporter.client_scope.pluck(:id)
        expect(ids).not_to include(embargoed_dest.id)
        expect(ids).to include(dest_client.id)
      end

      it 'includes a client whose exclusion flag was set to false (uncheck scenario)' do
        # Set true then false so a ClientAttribute row exists with flag: false.
        # A client with no row at all would also pass — this ensures the flag: true
        # filter in externally_excluded_client_ids is load-bearing.
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: false)
        expect(exporter.client_scope.pluck(:id)).to include(dest_client.id)
      end

      it 'includes a client whose warehouse_client is exactly at the 1-week embargo boundary (boundary is exclusive)' do
        new_source = create(:hud_client, data_source: source_ds)
        create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        non_embargoed_dest = make_destination(new_source, warehouse_created_at: ClientExternalDataSharing::EMBARGO_PERIOD.ago)
        expect(exporter.client_scope.pluck(:id)).to include(non_embargoed_dest.id)
      end

      it 'excludes a client that is both flagged and embargoed, without affecting other clients' do
        new_source = create(:hud_client, data_source: source_ds)
        create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        double_restricted = make_destination(new_source, warehouse_created_at: 2.days.ago)
        ClientExternalDataSharing.new(double_restricted).set_exclusion!(value: true)
        ids = exporter.client_scope.pluck(:id)
        expect(ids).not_to include(double_restricted.id)
        expect(ids).to include(dest_client.id)
      end

      it 'does not issue more queries as the number of excluded clients grows (no N+1)' do
        3.times do
          src = create(:hud_client, data_source: source_ds)
          create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: src.PersonalID)
          ClientExternalDataSharing.new(make_destination(src)).set_exclusion!(value: true)
        end
        exporter_3 = build_exporter([project.id])
        count_3 = 0
        ActiveSupport::Notifications.subscribed(->(*) { count_3 += 1 }, 'sql.active_record') do
          exporter_3.client_scope.to_a
        end

        # Add three more clients, for a total of 6
        3.times do
          src = create(:hud_client, data_source: source_ds)
          create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: src.PersonalID)
          ClientExternalDataSharing.new(make_destination(src)).set_exclusion!(value: true)
        end
        exporter_6 = build_exporter([project.id])
        count_6 = 0
        ActiveSupport::Notifications.subscribed(->(*) { count_6 += 1 }, 'sql.active_record') do
          exporter_6.client_scope.to_a
        end

        expect(count_6).to be <= count_3
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
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end
    end

    context 'when config is enabled' do
      before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

      it 'excludes enrollments for a client flagged for exclusion' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(exporter.enrollment_scope.pluck(:id)).not_to include(enrollment.id)
      end

      it 'excludes enrollments for a client whose warehouse_client was created less than 1 week ago, without affecting older clients' do
        new_source = create(:hud_client, data_source: source_ds)
        new_enrollment = create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        make_destination(new_source, warehouse_created_at: 2.days.ago)
        ids = exporter.enrollment_scope.pluck(:id)
        expect(ids).not_to include(new_enrollment.id)
        expect(ids).to include(enrollment.id)
      end

      it 'includes enrollments for a client whose exclusion flag was set to false (uncheck scenario)' do
        # Set true then false so a ClientAttribute row exists with flag: false.
        # A client with no row at all would also pass — this ensures the flag: true
        # filter in externally_excluded_client_ids is load-bearing.
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: false)
        expect(exporter.enrollment_scope.pluck(:id)).to include(enrollment.id)
      end

      it 'includes enrollments for a client whose warehouse_client is exactly at the 1-week embargo boundary (boundary is exclusive)' do
        new_source = create(:hud_client, data_source: source_ds)
        new_enrollment = create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        make_destination(new_source, warehouse_created_at: ClientExternalDataSharing::EMBARGO_PERIOD.ago)
        expect(exporter.enrollment_scope.pluck(:id)).to include(new_enrollment.id)
      end

      it 'excludes enrollments for a client that is both flagged and embargoed, without affecting other clients' do
        new_source = create(:hud_client, data_source: source_ds)
        new_enrollment = create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: new_source.PersonalID)
        double_restricted = make_destination(new_source, warehouse_created_at: 2.days.ago)
        ClientExternalDataSharing.new(double_restricted).set_exclusion!(value: true)
        ids = exporter.enrollment_scope.pluck(:id)
        expect(ids).not_to include(new_enrollment.id)
        expect(ids).to include(enrollment.id)
      end

      it 'does not issue more queries as the number of excluded clients grows (no N+1)' do
        3.times do
          src = create(:hud_client, data_source: source_ds)
          create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: src.PersonalID)
          ClientExternalDataSharing.new(make_destination(src)).set_exclusion!(value: true)
        end
        exporter_3 = build_exporter([project.id])
        count_3 = 0
        ActiveSupport::Notifications.subscribed(->(*) { count_3 += 1 }, 'sql.active_record') do
          exporter_3.enrollment_scope.to_a
        end

        # Add three more clients, for a total of 6
        3.times do
          src = create(:hud_client, data_source: source_ds)
          create(:hud_enrollment, data_source: source_ds, ProjectID: project.ProjectID, PersonalID: src.PersonalID)
          ClientExternalDataSharing.new(make_destination(src)).set_exclusion!(value: true)
        end
        exporter_6 = build_exporter([project.id])
        count_6 = 0
        ActiveSupport::Notifications.subscribed(->(*) { count_6 += 1 }, 'sql.active_record') do
          exporter_6.enrollment_scope.to_a
        end

        expect(count_6).to be <= count_3
      end
    end
  end
end
