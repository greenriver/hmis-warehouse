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

    it 'has no smoke' do
      unit_type = create(:hmis_unit_type)
      unit_type_mper_id = SecureRandom.uuid
      mper.create_external_id(source: unit_type, value: unit_type_mper_id)

      capacity = 3
      units = capacity.times.map do
        create(:hmis_unit, project: project, unit_type: unit_type)
      end

      enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: project, client: c1, user: u1)
      enrollment.assign_unit(unit: units.first, start_date: Date.current, user: hmis_user)
      enrollment.save!

      result = HmisExternalApis::OauthClientResult.new(parsed_body: {})
      expect_any_instance_of(HmisExternalApis::OauthClientConnection).to receive(:patch)
        .with(
          'Unit/Capacity',
          {
            'availableUnits' => capacity - 1,
            'capacity' => capacity,
            'programID' => project.ProjectID,
            'requestedBy' => hmis_user.email,
            'unitTypeID' => unit_type_mper_id,
          },
        )
        .and_return(result)

      HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now
    end
  end
end
