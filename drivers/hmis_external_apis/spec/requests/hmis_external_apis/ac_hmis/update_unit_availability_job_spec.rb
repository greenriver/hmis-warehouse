###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob do
  describe 'update unit capacity' do
    include_context 'hmis base setup'

    let(:mper) do
      create(:ac_hmis_mper_credential)
      ::HmisExternalApis::AcHmis::Mper.new
    end

    let!(:link_creds) do
      create(:ac_hmis_link_credential)
    end

    let(:project) do
      p1
    end

    let(:requested_by) do
      'test@example.com'
    end

    it 'has no smoke' do
      unit_type = create(:hmis_unit_type)
      unit_type_mper_id = SecureRandom.uuid
      mper.create_external_id(source: unit_type, value: unit_type_mper_id)

      result = HmisExternalApis::OauthClientResult.new(parsed_body: {})
      expect_any_instance_of(HmisExternalApis::AcHmis::LinkApi).to receive(:update_unit_capacity)
        .with(
          {
            'availableUnits' => 1,
            'programID' => project.ProjectID,
            'requestedBy' => requested_by,
            'unitTypeID' => unit_type_mper_id,
          },
        )
        .and_return(result)

      create(:hmis_unit, project: project, unit_type: unit_type)

      HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(
        project_id: project.id,
        unit_type_id: unit_type.id,
        requested_by: 'test@example.com',
      )
    end
  end
end
