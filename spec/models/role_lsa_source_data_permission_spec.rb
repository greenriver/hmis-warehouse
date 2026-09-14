###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'can_download_lsa_source_data' do
    it 'is a registered permission' do
      expect(Role.permissions).to include(:can_download_lsa_source_data)
    end

    it 'has a column on roles' do
      expect(Role.column_names).to include('can_download_lsa_source_data')
    end

    it 'is described for the admin UI' do
      metadata = Role.permissions_with_descriptions[:can_download_lsa_source_data]

      expect(metadata[:description]).to be_present
      expect(metadata[:category]).to eq('Reporting')
      expect(metadata[:sub_category]).to eq('Exporting')
      expect(metadata[:administrative]).to eq(false)
    end

    # Encodes the no-backfill decision: a role has to be granted this explicitly.
    it 'defaults to false on a new role' do
      expect(create(:role).can_download_lsa_source_data).to eq(false)
    end

    it 'is not implied by can_export_hmis_data' do
      role = create(:role, can_export_hmis_data: true)

      expect(role.can_download_lsa_source_data).to eq(false)
    end
  end
end
