###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Hmis::Hud::HmisService, type: :model do
  let(:ds1) { create :hmis_data_source }
  let!(:service_type) { create :hmis_custom_service_type_for_hud_service, data_source: ds1, name: 'some service' }
  let!(:service) { create :hmis_hud_service, data_source: ds1, record_type: service_type.hud_record_type, type_provided: service_type.hud_type_provided }
  let!(:project) { service.enrollment.project }

  it 'works' do
    # contains view model of the service
    expect(project.hmis_services).to contain_exactly(Hmis::Hud::HmisService.find_by(owner: service))
  end

  describe '.with_view_ids' do
    # Same primary key as the HUD service, so only the view id prefix tells them apart.
    let!(:custom_service) { create :hmis_custom_service, id: service.id, data_source: ds1 }

    it 'resolves a HUD service view id to that service only' do
      expect(described_class.with_view_ids("1#{service.id}").map(&:owner)).to contain_exactly(service)
    end

    it 'resolves a custom service view id to that service only' do
      expect(described_class.with_view_ids("2#{custom_service.id}").map(&:owner)).to contain_exactly(custom_service)
    end

    it 'resolves a mixed list of integer ids' do
      ids = ["1#{service.id}".to_i, "2#{custom_service.id}".to_i]
      expect(described_class.with_view_ids(ids).map(&:owner)).to contain_exactly(service, custom_service)
    end

    it 'returns no rows for malformed ids' do
      ['1', "1#{service.id}abc", "10#{service.id}", '1' + '9' * 25, '', nil].each do |id|
        expect(described_class.with_view_ids(id).to_a).to eq([]), "expected no rows for #{id.inspect}"
      end
    end

    it 'uses the primary keys of the underlying tables' do
      described_class.connection.execute('SET LOCAL enable_seqscan = off')
      relation = described_class.with_view_ids(["1#{service.id}", "2#{custom_service.id}"])
      plan = described_class.connection.select_values("EXPLAIN #{relation.to_sql}").join("\n")

      expect(plan).to include('Services_pkey', 'CustomServices_pkey')
      expect(plan).not_to match(/Seq Scan on "(Custom)?Services"/)
    end
  end

  # Reverted behavior for performance reasons. If this happens, a data cleanup should occur instead.
  # it 'does not include services for an enrollment with an invalid client id' do
  #   expect do
  #     # update_column skips validation
  #     service.enrollment.update_column(:personal_id, 'this_is_an_invalid_client_id')
  #   end.to change(project.hmis_services, :count).by(-1)
  # end

  # Reverted behavior for performance reasons. If this happens, a data cleanup should occur instead.
  # it 'does not include services with an invalid client id' do
  #   expect do
  #     # update_column skips validation
  #     service.update_column(:personal_id, 'this_is_an_invalid_client_id')
  #   end.to change(project.hmis_services, :count).by(-1)
  # end
end
