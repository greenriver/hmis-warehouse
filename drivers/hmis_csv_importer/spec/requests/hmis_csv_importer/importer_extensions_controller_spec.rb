###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::ImporterExtensionsController, type: :request do
  let(:data_source) { create(:data_source) }
  let(:user) do
    u = create(:user)
    u.legacy_roles << role
    u
  end

  before do
    allow(GrdaWarehouse::DataSource).to receive(:editable_by).with(user).and_return(
      GrdaWarehouse::DataSource.where(id: data_source.id),
    )
    sign_in user
  end

  context 'without can_manage_config permission' do
    let(:role) { create(:role, can_edit_data_sources: true, can_view_imports: true) }

    it 'blocks the update and leaves the config unchanged' do
      data_source.update!(pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true })

      put hmis_csv_importer_importer_extension_path(data_source), params: { extensions: { 'placeholder' => '0' } }

      expect(flash[:alert]).to be_present
      expect(data_source.reload.pre_process_hooks).to eq('HmisCsvImporter::Loader::HudKeyRemapper' => true)
    end
  end

  context 'without can_view_imports permission' do
    let(:role) { create(:role, can_edit_data_sources: true, can_manage_config: true) }

    it 'blocks viewing the edit form' do
      get edit_hmis_csv_importer_importer_extension_path(data_source)

      expect(flash[:alert]).to be_present
    end
  end

  context 'when the data source is outside the user\'s editable_by scope' do
    let(:role) { create(:role, can_manage_config: true, can_view_imports: true) }

    before do
      allow(GrdaWarehouse::DataSource).to receive(:editable_by).with(user).and_return(GrdaWarehouse::DataSource.none)
    end

    it 'renders not found' do
      get edit_hmis_csv_importer_importer_extension_path(data_source)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with can_manage_config and can_view_imports permission' do
    let(:role) { create(:role, can_edit_data_sources: true, can_manage_config: true, can_view_imports: true) }

    describe 'PUT update' do
      it 'resets pre_process_hooks to empty when nothing is checked, not leaving stale flags' do
        data_source.update!(pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true })

        # A real submission always includes every checkbox's hidden "0" fallback field (see the
        # `simple_form_for :extensions` view), so `extensions` is never truly an empty hash -- an
        # actually-empty nested hash param gets dropped entirely by Rack, unlike this real-world shape.
        put hmis_csv_importer_importer_extension_path(data_source), params: { extensions: { 'placeholder' => '0' } }

        expect(data_source.reload.pre_process_hooks).to eq({})
      end

      it 'writes the checked extension into its config bucket' do
        put hmis_csv_importer_importer_extension_path(data_source), params: {
          extensions: { 'HmisCsvImporter::Aggregated::CombineEnrollments' => '1' },
        }

        expect(data_source.reload.import_aggregators).to eq(
          'Enrollment' => ['HmisCsvImporter::Aggregated::CombineEnrollments'],
        )
      end

      it 'removes a previously enabled extension once its checkbox is unchecked' do
        data_source.update!(import_aggregators: { 'Enrollment' => ['HmisCsvImporter::Aggregated::CombineEnrollments'] })

        put hmis_csv_importer_importer_extension_path(data_source), params: {
          extensions: { 'HmisCsvImporter::Aggregated::CombineEnrollments' => '0' },
        }

        expect(data_source.reload.import_aggregators).to eq({})
      end
    end
  end
end
