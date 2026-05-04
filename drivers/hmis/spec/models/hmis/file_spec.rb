###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files]) }

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
      let!(:access_control) { create_access_control(hmis_user, ds2, with_permission: [:can_manage_own_client_files]) }
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
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files]) }

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
    end

    context 'with many files' do
      before do
        30.times do
          enrollment = create :hmis_hud_enrollment, data_source: ds1, entry_date: 1.month.ago
          create :file, enrollment: enrollment, client: enrollment.client, blob: blob
        end
      end

      it 'makes a reasonable number of db queries' do
        expect do
          Hmis::File.viewable_by(hmis_user)
        end.to make_database_queries(count: 50..65)
      end
    end
  end
end
