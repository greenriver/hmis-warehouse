###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::FilesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:no_data_source_collection) { create :collection }
  let!(:can_manage_client_files) { create :role, can_manage_client_files: true, can_confirm_housing_release: true }

  before(:each) do
    sign_in user
    setup_access_control(user, can_manage_client_files, no_data_source_collection)
    allow_any_instance_of(Clients::FilesController).to receive(:destination_searchable_client_scope).and_return(
      GrdaWarehouse::Hud::Client.where(id: client.id),
    )
    allow_any_instance_of(Clients::FilesController).to receive(:require_window_file_access!).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:can_manage_client_files?).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:can_confirm_housing_release?).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:window_visible?).and_return(true)
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
  end

  describe 'POST #create' do
    let(:file_upload) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
    end

    context 'when auto_confirm_consent is enabled' do
      before do
        config = GrdaWarehouse::Config.first
        config.update!(auto_confirm_consent: true)
      end

      it 'automatically confirms the consent form even when consent_form_confirmed is not set' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '0',
            coc_codes: [''],
          },
        }
        expect(GrdaWarehouse::Config.get(:auto_confirm_consent)).to be true
        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
      end
    end

    context 'when auto_confirm_consent is disabled' do
      before do
        config = GrdaWarehouse::Config.first
        config.update!(auto_confirm_consent: false)
      end

      it 'does not automatically confirm the consent form' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '0',
            coc_codes: [''],
          },
        }

        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be false
        expect(file.client.consent_form_valid?).to be false
      end

      it 'user is able to confirm the consent form' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '1',
            coc_codes: [''],
          },
        }

        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
      end
    end
  end
end
