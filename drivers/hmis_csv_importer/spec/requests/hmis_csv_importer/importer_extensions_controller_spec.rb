###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::ImporterExtensionsController, type: :request do
  let(:data_source) { create(:data_source) }
  let(:role) { create(:role, can_edit_data_sources: true, can_manage_config: true, can_view_imports: true) }
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

  describe 'PUT update' do
    it 'resets pre_process_hooks to empty when nothing is checked, not leaving stale flags' do
      data_source.update!(pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true })

      # A real submission always includes every checkbox's hidden "0" fallback field (see the
      # `simple_form_for :extensions` view), so `extensions` is never truly an empty hash -- an
      # actually-empty nested hash param gets dropped entirely by Rack, unlike this real-world shape.
      put hmis_csv_importer_importer_extension_path(data_source), params: { extensions: { 'placeholder' => '0' } }

      expect(data_source.reload.pre_process_hooks).to eq({})
    end
  end
end
