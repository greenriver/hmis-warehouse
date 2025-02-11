###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  end
end
