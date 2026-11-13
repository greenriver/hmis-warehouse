###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::FilesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:client) { warehouse_client.destination }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:can_manage_client_files) do
    create :role, can_manage_client_files: true, can_confirm_housing_release: true, can_see_own_file_uploads: true, can_search_own_clients: true
  end

  def grant_client_access(user, role)
    collection = create(:collection)
    collection.set_viewables({ data_sources: [warehouse_client.source.data_source_id] })
    setup_access_control(user, role, collection)
  end

  before(:each) do
    sign_in user
    grant_client_access(user, can_manage_client_files)
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  describe 'POST #create' do
    let(:file_upload) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
    end

    context 'when auto_confirm_consent is enabled' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, auto_confirm_consent: true
        GrdaWarehouse::Config.invalidate_cache
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
        expect(response).to have_http_status(:redirect)
        expect(GrdaWarehouse::Config.get(:auto_confirm_consent)).to be true
        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
        expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)&.status).to eq('full')
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

    context 'when auto_confirm_consent is disabled' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, auto_confirm_consent: false
        GrdaWarehouse::Config.invalidate_cache
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
        expect(GrdaWarehouse::Config.get(:auto_confirm_consent)).to be false
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

    context 'under a Use Expiration Date release duration' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, release_duration: 'Use Expiration Date'
        GrdaWarehouse::Config.invalidate_cache
      end

      it 're-renders the form and saves nothing when a confirmed consent form has no expiration date' do
        expect do
          post client_files_path(client_id: client.id), params: {
            grda_warehouse_client_file: {
              client_file: file_upload,
              tag_list: [consent_tag.name],
              effective_date: Date.current,
              consent_form_confirmed: '1',
              coc_codes: [''],
            },
          }
        end.not_to change(GrdaWarehouse::ClientFile, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Expiration date is required')
        expect(client.reload.consent_form_id).to be_nil
        expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: client.id)).to be_empty
      end
    end
  end

  describe 'consent revocation and deletion' do
    let!(:file) do
      create :client_file, client: client, tags: [consent_tag], effective_date: 5.days.ago, expiration_date: 1.year.from_now.to_date
    end

    def use_config(roi_model, release_duration)
      GrdaWarehouse::Config.delete_all
      create :config_b, roi_model: roi_model, release_duration: release_duration
      GrdaWarehouse::Config.invalidate_cache
    end

    def roi_row
      GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
    end

    def revoke_consent_form
      patch client_file_path(client_id: client.id, id: file.id),
            params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
            xhr: true
      expect(response).to have_http_status(:ok)
    end

    def run_nightly_rebuild
      GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [client.id])
    end

    ['Indefinite', 'Use Expiration Date', 'One Year', 'Two Years'].each do |release_duration|
      context "under implied consent with a #{release_duration} release duration" do
        before do
          use_config(:implicit, release_duration)
          file.confirm_consent!
        end

        it 'keeps the client marked revoked, with a revoked ROI row, through the nightly rebuild' do
          expect(roi_row.status).to eq('full')

          revoke_consent_form
          expect(roi_row.status).to eq('revoked')
          run_nightly_rebuild

          client.reload
          expect(client.housing_release_status).to eq(Consent::Implied.revoked_consent_string)
          expect(roi_row.status).to eq('revoked')
          expect(client.full_or_partial_release?).to be false
          expect(GrdaWarehouse::Hud::Client.consent_form_valid.where(id: client.id)).to be_empty
        end
      end
    end

    context 'under default consent' do
      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'clears the release and removes the ROI row when the request completes' do
        expect(roi_row.status).to eq('full')

        revoke_consent_form

        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end

      it 'keeps the release and the ROI row when the revoked file fails validation' do
        # update only accepts the consent fields, none of which can fail validation on a revocation, so an invalid
        # row stands in for any save failure; the revocation must still roll back with it
        file.update_columns(visible_in_window: nil)

        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Visible in window', 'not included in the list')
        expect(file.reload.consent_revoked_at).to be_nil
        expect(client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end
    end

    context 'when the user can manage files but cannot confirm releases' do
      let!(:file_manager) { create :acl_user }

      before do
        use_config(:explicit, 'Indefinite')
        grant_client_access(file_manager, create(:role, can_manage_client_files: true, can_see_own_file_uploads: true, can_search_own_clients: true))
        sign_in file_manager
      end

      it 'saves the other changes but leaves the consent form unconfirmed, with no ROI row' do
        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_form_confirmed: '1', consent_form_signed_on: 3.days.ago.to_date.to_s } },
              xhr: true

        expect(response).to have_http_status(:ok)
        file.reload
        expect(file.consent_form_signed_on).to eq(3.days.ago.to_date)
        expect(file.consent_form_confirmed).to be_nil
        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end
    end

    context 'when the user cannot search for the client' do
      let!(:outsider) { create :acl_user }

      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
        # Same permissions as the file manager, through a collection that holds no data sources
        setup_access_control(outsider, create(:role, can_manage_client_files: true, can_confirm_housing_release: true, can_see_own_file_uploads: true, can_search_own_clients: true), create(:collection))
        sign_in outsider
      end

      it 'returns not found for a revocation and leaves the consent in place' do
        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(file.reload.consent_revoked_at).to be_nil
        expect(client.reload.consent_form_id).to eq(file.id)
        expect(roi_row.status).to eq('full')
      end

      it 'returns not found for a deletion and leaves the consent in place' do
        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: file.id)).to exist
        expect(client.reload.consent_form_id).to eq(file.id)
        expect(roi_row.status).to eq('full')
      end
    end

    context "when the request names another client's consent form" do
      let!(:other_client) { create :grda_warehouse_hud_client }
      let!(:other_file) { create :client_file, client: other_client, tags: [consent_tag], effective_date: 5.days.ago }

      before do
        use_config(:explicit, 'Indefinite')
        other_file.confirm_consent!
      end

      it 'returns not found for a revocation and leaves the other client consent in place' do
        patch client_file_path(client_id: client.id, id: other_file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(other_file.reload.consent_revoked_at).to be_nil
        expect(other_client.reload.consent_form_id).to eq(other_file.id)
      end

      it 'returns not found for a deletion and leaves the other client consent in place' do
        delete client_file_path(client_id: client.id, id: other_file.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: other_file.id)).to exist
        expect(other_client.reload.consent_form_id).to eq(other_file.id)
      end
    end

    describe 'DELETE #destroy' do
      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'removes the ROI row when the active consent form is deleted' do
        expect(roi_row.status).to eq('full')

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end

      it 'keeps the file, the release, and the ROI row when the active consent form fails validation on delete' do
        file.update_columns(visible_in_window: nil)

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(flash[:error]).to eq('File could not be deleted.')
        expect(GrdaWarehouse::ClientFile.where(id: file.id)).to exist
        client.reload
        expect(client.consent_form_id).to eq(file.id)
        expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end

      it 'keeps the release and the ROI row when an older, unconfirmed consent form is deleted' do
        older_form = create :client_file, client: client, tags: [consent_tag], effective_date: 1.year.ago

        delete client_file_path(client_id: client.id, id: older_form.id)

        expect(GrdaWarehouse::ClientFile.where(id: older_form.id)).to be_empty
        client.reload
        expect(client.consent_form_id).to eq(file.id)
        expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end
    end

    describe 'DELETE #destroy under implied consent' do
      before do
        use_config(:implicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'falls back to implied consent with a partial ROI row when the active consent form is deleted' do
        expect(roi_row.status).to eq('full')

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(client.reload.housing_release_status).to eq(Consent::Implied.no_release_string)
        expect(roi_row.status).to eq('partial')
      end
    end
  end

  describe 'confidential files' do
    let!(:other_tag) { create :available_file_tag, name: 'Other Document' }
    let!(:enrollment_project) { create :hud_project }
    let!(:data_source_project) { create :hud_project }
    let!(:hidden_project) { create :hud_project }
    let!(:public_file) { create :client_file, client: client, tags: [other_tag] }
    let!(:enrollment_file) { create_confidential_file(enrollment: create_enrollment(enrollment_project)) }
    let!(:data_source_file) { create_confidential_file(data_source: data_source_project.data_source) }
    let!(:hidden_file) do
      create_confidential_file(
        enrollment: create_enrollment(hidden_project),
        note: 'Hidden note',
        user: create(:user, first_name: 'Hidden', last_name: 'Uploader'),
      )
    end

    def create_enrollment(project)
      create :hud_enrollment, data_source_id: project.data_source_id, ProjectID: project.ProjectID, PersonalID: 'confidential-client'
    end

    def create_confidential_file(**attrs)
      tag = create :available_file_tag, name: "Confidential Document #{SecureRandom.hex(4)}"
      create :client_file, client: client, tags: [tag], confidential: true, **attrs
    end

    def zip_entry_names
      names = []
      Zip::InputStream.open(StringIO.new(response.body)) do |zip|
        while (entry = zip.get_next_entry)
          names << entry.name
        end
      end
      names
    end

    context 'for a file manager with confidential access at some projects' do
      let!(:confidential_user) { create :acl_user }

      before do
        manager_role = create :role, can_manage_client_files: true, can_see_own_file_uploads: true, can_search_own_clients: true
        grant_client_access(confidential_user, manager_role)
        confidential_role = create :role, can_see_confidential_files: true
        grant_project_access(confidential_user, confidential_role, [enrollment_project, data_source_project], mode: :acl)
        sign_in confidential_user
      end

      describe 'uploading a confidential file' do
        let(:file_upload) do
          fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
        end

        def post_confidential_file(**attrs)
          post client_files_path(client_id: client.id), params: {
            grda_warehouse_client_file: {
              client_file: file_upload,
              tag_list: [other_tag.name],
              confidential: '1',
              coc_codes: [''],
              **attrs,
            },
          }
        end

        # Link a source client at the project's data source so the enrollment belongs to this client
        def create_client_enrollment(project)
          source_client = create :grda_warehouse_hud_client, data_source_id: project.data_source_id
          create :warehouse_client,
                 destination: client,
                 source: source_client,
                 data_source_id: project.data_source_id
          create :hud_enrollment,
                 data_source_id: project.data_source_id,
                 ProjectID: project.ProjectID,
                 PersonalID: source_client.PersonalID
        end

        it 'saves the file as confidential with its enrollment' do
          enrollment = create_client_enrollment(enrollment_project)

          expect do
            post_confidential_file(enrollment_id: enrollment.id)
          end.to change(GrdaWarehouse::ClientFile, :count).by(1)

          file = GrdaWarehouse::ClientFile.order(:id).last
          expect(response).to have_http_status(:redirect)
          expect(file.confidential).to be true
          expect(file.enrollment_id).to eq(enrollment.id)
          expect(GrdaWarehouse::ClientFile.confidential_visible_by(confidential_user)).to include(file)
        end

        it 'saves the file as confidential with its data source' do
          data_source_id = data_source_project.data_source_id

          post_confidential_file(data_source_id: data_source_id)

          file = GrdaWarehouse::ClientFile.order(:id).last
          expect(response).to have_http_status(:redirect)
          expect(file.confidential).to be true
          expect(file.data_source_id).to eq(data_source_id)
          expect(GrdaWarehouse::ClientFile.confidential_visible_by(confidential_user)).to include(file)
        end

        it 're-renders the form and saves nothing without an enrollment or data source' do
          expect do
            post_confidential_file
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Failed to upload file')
        end

        it 'saves a non-confidential file with an allowed enrollment link' do
          enrollment = create_client_enrollment(enrollment_project)

          expect do
            post_confidential_file(confidential: '0', enrollment_id: enrollment.id)
          end.to change(GrdaWarehouse::ClientFile, :count).by(1)

          file = GrdaWarehouse::ClientFile.order(:id).last
          expect(file.confidential).to be false
          expect(file.enrollment_id).to eq(enrollment.id)
        end

        it 'rejects a non-confidential file linked to an enrollment without the permission' do
          enrollment = create_client_enrollment(hidden_project)

          expect do
            post_confidential_file(confidential: '0', enrollment_id: enrollment.id)
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to redirect_to(confidential_user.my_root_path)
        end

        it 'rejects an enrollment at a project without the permission' do
          enrollment = create_client_enrollment(hidden_project)

          expect do
            post_confidential_file(enrollment_id: enrollment.id)
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to redirect_to(confidential_user.my_root_path)
        end

        it 'rejects a data source without the permission' do
          expect do
            post_confidential_file(data_source_id: hidden_project.data_source_id)
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to redirect_to(confidential_user.my_root_path)
        end

        it 'rejects an enrollment that belongs to another client' do
          other_project_enrollment = create :hud_enrollment,
                                            data_source_id: enrollment_project.data_source_id,
                                            ProjectID: enrollment_project.ProjectID,
                                            PersonalID: 'someone-else'

          expect do
            post_confidential_file(enrollment_id: other_project_enrollment.id)
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to redirect_to(confidential_user.my_root_path)
        end

        it 'rejects a confidential upload from a user without confidential access' do
          sign_in user

          expect do
            post_confidential_file(data_source_id: data_source_project.data_source_id)
          end.not_to change(GrdaWarehouse::ClientFile, :count)

          expect(response).to redirect_to(user.my_root_path)
        end
      end

      it 'returns not found for a download of a confidential file at a project without the permission' do
        get client_file_path(client_id: client.id, id: hidden_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for a preview of a confidential file at a project without the permission' do
        get preview_client_file_path(client_id: client.id, id: hidden_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for a thumbnail of a confidential file at a project without the permission' do
        get thumb_client_file_path(client_id: client.id, id: hidden_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for an update of a confidential file at a project without the permission' do
        patch client_file_path(client_id: client.id, id: hidden_file.id),
              params: { grda_warehouse_client_file: { expiration_date: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(hidden_file.reload.expiration_date).to be_nil
      end

      it 'downloads a confidential file through its enrollment project' do
        get client_file_path(client_id: client.id, id: enrollment_file.id)
        expect(response).to have_http_status(:ok)
      end

      it 'downloads a confidential file through its data source' do
        get client_file_path(client_id: client.id, id: data_source_file.id)
        expect(response).to have_http_status(:ok)
      end

      it 'leaves hidden confidential files out of a batch download' do
        file_ids = [public_file.id, enrollment_file.id, hidden_file.id].join(',')
        post batch_download_client_files_path(client_id: client.id), params: { batch_download: { file_ids: file_ids } }

        expect(response).to have_http_status(:ok)
        expected_names = [public_file, enrollment_file].map { |file| File.join(client.id.to_s, "#{file.tag_list.join('-')}.jpg") }
        expect(zip_entry_names).to match_array(expected_names)
      end

      it 'lists a hidden confidential file without its details' do
        get client_files_path(client_id: client.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("client-file-#{hidden_file.id}")
        expect(response.body).not_to include('Hidden note')
        expect(response.body).not_to include('Hidden Uploader')
        expect(response.body).not_to include(client_file_path(client_id: client.id, id: hidden_file.id))
      end

      it 'hides the details of a deleted confidential file only when the file is hidden' do
        hidden_file.update!(delete_reason: 99, delete_detail: 'Hidden reason')
        hidden_file.soft_delete!
        enrollment_file.update!(note: 'Visible note', delete_reason: 99, delete_detail: 'Visible reason')
        enrollment_file.soft_delete!

        get client_files_path(client_id: client.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Visible note', 'Visible reason')
        expect(response.body).not_to include('Hidden note')
        expect(response.body).not_to include('Hidden reason')
        expect(response.body).not_to include('Hidden Uploader')
      end
    end

    # viewable_project_ids reads only ACLs, so legacy users never see confidential files
    context 'for a legacy-permission file manager with confidential access at the project' do
      let!(:legacy_user) { create :user }

      before do
        legacy_role = create :role, can_manage_client_files: true, can_see_own_file_uploads: true, can_search_all_clients: true, can_see_confidential_files: true
        grant_project_access(legacy_user, legacy_role, [enrollment_project, data_source_project], mode: :legacy)
        sign_in legacy_user
      end

      it 'returns not found for a download of a confidential file' do
        get client_file_path(client_id: client.id, id: enrollment_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for a preview of a confidential file' do
        get preview_client_file_path(client_id: client.id, id: enrollment_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for a thumbnail of a confidential file' do
        get thumb_client_file_path(client_id: client.id, id: enrollment_file.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for an update of a confidential file' do
        patch client_file_path(client_id: client.id, id: enrollment_file.id),
              params: { grda_warehouse_client_file: { expiration_date: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(enrollment_file.reload.expiration_date).to be_nil
      end

      it 'leaves confidential files out of a batch download' do
        file_ids = [public_file.id, enrollment_file.id].join(',')
        post batch_download_client_files_path(client_id: client.id), params: { batch_download: { file_ids: file_ids } }

        expect(response).to have_http_status(:ok)
        expect(zip_entry_names).to eq([File.join(client.id.to_s, "#{public_file.tag_list.join('-')}.jpg")])
      end

      it 'lists a confidential file at its project without its details' do
        enrollment_file.update!(note: 'Enrollment note')

        get client_files_path(client_id: client.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("client-file-#{enrollment_file.id}")
        expect(response.body).not_to include('Enrollment note')
        expect(response.body).not_to include(client_file_path(client_id: client.id, id: enrollment_file.id))
      end

      it 'downloads a file that is not confidential' do
        get client_file_path(client_id: client.id, id: public_file.id)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'for a file manager without confidential access' do
      [:enrollment_file, :data_source_file, :hidden_file].each do |file_name|
        it "returns not found for a download of #{file_name}" do
          get client_file_path(client_id: client.id, id: send(file_name).id)
          expect(response).to have_http_status(:not_found)
        end
      end

      it 'downloads a file that is not confidential' do
        get client_file_path(client_id: client.id, id: public_file.id)
        expect(response).to have_http_status(:ok)
      end

      # Deleting does not expose contents, so destroy and show_delete_modal skip the confidential check
      it 'shows the delete modal for a hidden confidential file without its details' do
        get show_delete_modal_client_file_path(client_id: client.id, id: hidden_file.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Hidden note')
        expect(response.body).not_to include('Hidden Uploader')
      end

      it 'deletes a hidden confidential file' do
        delete client_file_path(client_id: client.id, id: hidden_file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(GrdaWarehouse::ClientFile.with_deleted.find(hidden_file.id).deleted_at).to be_present
      end
    end

    it 'ignores attributes other than the consent fields on update' do
      patch client_file_path(client_id: client.id, id: public_file.id),
            params: {
              grda_warehouse_client_file: {
                expiration_date: Date.current.to_s,
                note: 'Changed',
                tag_list: [consent_tag.name],
                confidential: '1',
                data_source_id: data_source_project.data_source_id,
                enrollment_id: hidden_file.enrollment_id,
                visible_in_window: '0',
                client_file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf'),
              },
            },
            xhr: true

      expect(response).to have_http_status(:ok)
      public_file.reload
      expect(public_file.expiration_date).to eq(Date.current)
      expect(public_file.note).to be_nil
      expect(public_file.tag_list).to eq([other_tag.name])
      expect(public_file.confidential).to be false
      expect(public_file.data_source_id).to be_nil
      expect(public_file.enrollment_id).to be_nil
      expect(public_file.visible_in_window).to be true
      expect(public_file.client_file.content_type).to eq('image/jpeg')
    end
  end
end
