###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'
require_relative '../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::File, type: :model do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1, FirstName: 'Lavender', LastName: 'Lime' }
  let!(:e1) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1 }
  let!(:access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_view_enrollment_details,
        :can_view_any_nonconfidential_client_files,
        :can_view_any_confidential_client_files,
      ],
    )
  end

  describe 'viewable_by scope' do
    context 'file has both enrollment and client' do
      let!(:file1) { create :file, client: c1, enrollment: e1, blob: blob }

      it 'returns the file if the user has access' do
        expect(Hmis::File.viewable_by(hmis_user)).to(include(file1))
      end

      it 'does not return the file if the user cannot view files' do
        remove_permissions(access_control, :can_view_any_nonconfidential_client_files)
        remove_permissions(access_control, :can_view_any_confidential_client_files)
        expect(Hmis::File.viewable_by(hmis_user)).to be_empty
      end

      context 'user has file permissions in a different project' do
        let!(:p2) { create :hmis_hud_project, data_source: ds1 }
        let!(:e2) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p2 }
        let!(:file2) { create :file, client: c1, enrollment: e2, blob: blob }

        it 'does not return the file' do
          # hmis_user has all perms at p1 only, so file2 (at p2) should not be visible via enrollment.
          expect(Hmis::File.viewable_by(hmis_user)).not_to include(file2)
        end
      end

      context 'if the file is confidential' do
        let!(:file1) { create :file, confidential: true, client: c1, enrollment: e1, blob: blob }

        it 'still returns the file even if the user cannot view confidential files (see comments on viewable_by scope)' do
          remove_permissions(access_control, :can_view_any_confidential_client_files)
          expect(Hmis::File.viewable_by(hmis_user)).to(include(file1))
        end
      end

      it 'does not return the file if the user cannot view enrollments' do
        remove_permissions(access_control, :can_view_enrollment_details)
        expect(Hmis::File.viewable_by(hmis_user)).to be_empty
      end
    end

    context 'file has client but not enrollment' do
      let!(:file1) { create :file, client: c1, enrollment: nil, blob: blob }

      it 'returns the file if the user has access' do
        expect(Hmis::File.viewable_by(hmis_user)).to(include(file1))
      end

      context 'if the user has no access on this client' do
        let!(:p2) { create :hmis_hud_project, data_source: ds1 }
        let!(:e1) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p2 } # move e1 to a different project

        it 'does not return the file' do
          expect(Hmis::File.viewable_by(hmis_user)).to be_empty
        end
      end

      context 'if the client has no enrollments, so it is an ambiguous "in-progress" client' do
        let!(:c2) { create :hmis_hud_client, data_source: ds1, FirstName: 'Almond', LastName: 'Hazelnut' }
        let!(:file1) { create :file, client: c2, blob: blob }

        it 'does return the file' do
          expect(Hmis::File.viewable_by(hmis_user)).to(include(file1))
        end
      end

      it 'does not return the file if the user cannot view clients' do
        remove_permissions(access_control, :can_view_clients)
        expect(Hmis::File.viewable_by(hmis_user)).to be_empty
      end
    end

    context 'user has can_manage_own_client_files' do
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files, :can_view_clients]) }

      it 'does not return the file' do
        expect(Hmis::File.viewable_by(hmis_user)).to be_empty
      end

      context "unless it is this user's file" do
        let!(:file1) { create :file, client: c1, user: hmis_user, blob: blob }

        it 'returns the file' do
          expect(Hmis::File.viewable_by(hmis_user)).to(include(file1))
        end
      end
    end

    context 'user has can_manage_own_client_files only in another data source' do
      let!(:ds2) { create :hmis_data_source }
      let!(:access_control) { create_access_control(hmis_user, ds2, with_permission: [:can_manage_own_client_files, :can_view_clients]) }
      let!(:file1) { create :file, client: c1, user: hmis_user, blob: blob }

      it 'does not return own files for clients in the current data source' do
        expect(Hmis::File.viewable_by(hmis_user)).not_to include(file1)
      end
    end

    context 'file belongs to a client in a different data source' do
      let!(:ds2) { create :hmis_data_source }
      let!(:p_ds2) { create :hmis_hud_project, data_source: ds2 }
      let!(:c_ds2) { create :hmis_hud_client, data_source: ds2 }
      let!(:e_ds2) { create :hmis_hud_enrollment, client: c_ds2, data_source: ds2, project: p_ds2 }
      let!(:file_ds2) { create :file, client: c_ds2, enrollment: e_ds2, blob: blob, user: hmis_user }
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files, :can_view_clients]) }

      before do
        # Grant hmis_user file access at ds2 as well, but hmis_user is logged in at ds1.
        create_access_control(
          hmis_user,
          p_ds2,
          with_permission: [
            :can_view_clients,
            :can_view_project,
            :can_view_enrollment_details,
            :can_view_any_nonconfidential_client_files,
            :can_view_any_confidential_client_files,
          ],
        )
      end

      it 'does not return files from a different data source' do
        expect(Hmis::File.viewable_by(hmis_user)).not_to include(file_ds2)
      end

      it 'does not return files from a different data source when its client is requested' do
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [c_ds2.id])).to be_empty
      end
    end

    context 'user has can_manage_own_client_files but cannot view the client' do
      let!(:hidden_project) { create :hmis_hud_project, data_source: ds1 }
      let!(:hidden_client) { create :hmis_hud_client, data_source: ds1 }
      let!(:hidden_enrollment) { create :hmis_hud_enrollment, client: hidden_client, data_source: ds1, project: hidden_project }
      let!(:own_file_on_hidden_client) { create :file, client: hidden_client, blob: blob, user: hmis_user }
      let!(:own_enrollment_file_on_hidden_client) { create :file, client: hidden_client, enrollment: hidden_enrollment, blob: blob, user: hmis_user }
      let!(:own_file_on_visible_client) { create :file, client: c1, blob: blob, user: hmis_user }

      before do
        # Can view clients only at p1, so hidden_client (enrolled only at hidden_project) is not viewable
        create_access_control(hmis_user, p1, with_permission: [:can_manage_own_client_files, :can_view_clients])
      end

      it 'returns own files only on clients the user can view' do
        expect(Hmis::File.viewable_by(hmis_user)).to include(own_file_on_visible_client)
        expect(Hmis::File.viewable_by(hmis_user)).not_to include(own_file_on_hidden_client, own_enrollment_file_on_hidden_client)
      end

      it 'does not return own files on a client the user cannot view when that client is requested' do
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [hidden_client.id])).to be_empty
      end

      it 'does not return own files on a soft-deleted client' do
        c1.update_columns(DateDeleted: Time.current)
        expect(Hmis::File.viewable_by(hmis_user)).not_to include(own_file_on_visible_client)
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [c1.id])).not_to include(own_file_on_visible_client)
      end
    end

    context 'with client_ids' do
      let!(:c2) { create :hmis_hud_client, data_source: ds1 }
      let!(:e2) { create :hmis_hud_enrollment, client: c2, data_source: ds1, project: p1 }
      let!(:p2) { create :hmis_hud_project, data_source: ds1 }
      let!(:e3) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p2 }
      let!(:other_user) { create(:user).related_hmis_user(ds1) }
      let!(:c1_client_file) { create :file, client: c1, blob: blob, user: other_user }
      let!(:c1_enrollment_file) { create :file, client: c1, enrollment: e1, blob: blob, user: other_user }
      # hmis_user has no file permissions at p2, so these are only visible via can_manage_own_client_files
      let!(:c1_own_file_at_p2) { create :file, client: c1, enrollment: e3, blob: blob, user: hmis_user }
      let!(:c1_other_file_at_p2) { create :file, client: c1, enrollment: e3, blob: blob, user: other_user }
      let!(:c2_file) { create :file, client: c2, enrollment: e2, blob: blob, user: hmis_user }

      before do
        create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files, :can_view_clients])
      end

      it 'returns the same files as the unfiltered scope, limited to those clients' do
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [c1.id])).to contain_exactly(c1_client_file, c1_enrollment_file, c1_own_file_at_p2)
        expect(Hmis::File.viewable_by(hmis_user).where(client_id: c1.id)).to contain_exactly(c1_client_file, c1_enrollment_file, c1_own_file_at_p2)
      end

      it 'returns files for every requested client' do
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [c1.id, c2.id])).to contain_exactly(c1_client_file, c1_enrollment_file, c1_own_file_at_p2, c2_file)
      end

      it 'treats empty client_ids as no client filter' do
        expect(Hmis::File.viewable_by(hmis_user, client_ids: [])).to match_array(Hmis::File.viewable_by(hmis_user))
      end
    end

    context 'with many files' do
      before do
        30.times do
          enrollment = create :hmis_hud_enrollment, project: p1, data_source: ds1, entry_date: 1.month.ago
          create :file, enrollment: enrollment, client: enrollment.client, blob: blob
        end
      end

      it 'makes a reasonable number of db queries' do
        expect do
          files = Hmis::File.viewable_by(hmis_user)
          expect(files.size).to be >= 30
        end.to make_database_queries(count: 5..20)
      end
    end
  end

  describe 'file size validation' do
    def build_file_with_size(byte_size)
      blob.update_column(:byte_size, byte_size)
      file = build(:file, client: c1, enrollment: e1)
      file.client_file.attach(blob)
      file
    end

    it 'accepts a file at the 12 MB limit' do
      expect(build_file_with_size(12.megabytes)).to be_valid
    end

    it 'rejects a file over the 12 MB limit' do
      file = build_file_with_size(12.megabytes + 1)
      expect(file).not_to be_valid
      expect(file.errors.where(:client_file).map { |e| e.options[:full_message] }).to include('File size should be less than 12 MB')
    end
  end
end
