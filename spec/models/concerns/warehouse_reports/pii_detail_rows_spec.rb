###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::PiiDetailRows, type: :model do
  let(:host_class) do
    Struct.new(:noop) do
      include WarehouseReports::PiiDetailRows
    end
  end
  let(:host) { host_class.new }
  let(:user) { create(:user) }
  let(:headers) { ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN', 'Program'] }
  let(:row) { [42, 'Jamie', 'Rivera', '1990-01-01', '123-45-6789', 'Shelter A'] }

  describe '#redact_pii_in_row' do
    context 'when the client is restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(true) }

      it 'redacts name, dob, and ssn while leaving non-pii columns untouched' do
        result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

        expect(result).to eq([42, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED, 'Shelter A'])
      end

      it 'does not mutate the original row' do
        original = row.dup
        host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

        expect(row).to eq(original)
      end
    end

    context 'when the client is not restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(false) }

      it 'passes pii columns through unchanged' do
        result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

        expect(result).to eq(row)
      end
    end

    context 'when headers contain no PII columns' do
      let(:headers) { ['Client ID', 'Program'] }
      let(:row) { [42, 'Shelter A'] }

      it 'returns the row as-is without resolving a policy' do
        expect(user).not_to receive(:reporting_policy_for_project)

        result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

        expect(result).to eq(row)
      end
    end

    context 'with a custom client_id_index' do
      let(:headers) { ['First Name', 'Last Name', 'Client ID'] }
      let(:row) { ['Jamie', 'Rivera', 42] }

      before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(true) }

      it 'looks up restriction using the id at the given index' do
        result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse, client_id_index: 2)

        expect(result).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, 42])
      end
    end

    context 'with mode: :download' do
      let(:redacted_row) do
        [42, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED, 'Shelter A']
      end

      before do
        allow(GrdaWarehouse::Config).to receive(:get).and_call_original
        allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(download_toggle)
      end

      context 'when include_pii_in_detail_downloads is off and the client is not restricted' do
        let(:download_toggle) { false }

        before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(false) }

        it 'redacts name, dob, and ssn' do
          result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :download)

          expect(result).to eq(redacted_row)
        end

        it 'leaves the same row untouched in mode: :browse' do
          result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

          expect(result).to eq(row)
        end
      end

      context 'when include_pii_in_detail_downloads is on and the client is not restricted' do
        let(:download_toggle) { true }

        before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(false) }

        it 'passes pii columns through unchanged' do
          result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :download)

          expect(result).to eq(row)
        end
      end

      context 'when include_pii_in_detail_downloads is on and the client is restricted' do
        let(:download_toggle) { true }

        before { allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(true) }

        it 'redacts name, dob, and ssn' do
          result = host.redact_pii_in_row(row, headers: headers, user: user, mode: :download)

          expect(result).to eq(redacted_row)
        end
      end
    end
  end
end

RSpec.describe WarehouseReports::PiiDetailRows, 'with a project or caller-supplied policy', type: :model do
  subject(:redactor) { Class.new { include WarehouseReports::PiiDetailRows }.new }

  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }
  let!(:project) { create(:hud_project) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:headers) { ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'] }
  let(:open_row) { [open_destination_client.id, 'Open', 'Doe', Date.new(1985, 6, 15), '987654321'] }
  let(:restricted_row) { [restricted_destination_client.id, 'Restricted', 'Client', Date.new(1990, 1, 1), '123456789'] }

  def redacted_row(client_id)
    [
      client_id,
      GrdaWarehouse::PiiProvider::NAME_REDACTED,
      GrdaWarehouse::PiiProvider::NAME_REDACTED,
      GrdaWarehouse::PiiProvider::REDACTED,
      GrdaWarehouse::PiiProvider::REDACTED,
    ]
  end

  before do
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(
      destination_id: restricted_destination_client.id,
      source_id: restricted_source_client.id,
      data_source_id: hmis_ds.id,
      id_in_source: restricted_source_client.id.to_s,
    )
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  it 'shows PII the project role allows when no policy is given' do
    result = redactor.redact_pii_in_row(open_row, headers: headers, user: user, mode: :browse, project_id: project.id)

    expect(result).to eq([open_destination_client.id, 'Open', 'Doe', Date.new(1985, 6, 15), '987-65-4321'])
  end

  it 'uses the given policy in place of the project role' do
    result = redactor.redact_pii_in_row(
      open_row,
      headers: headers,
      user: user,
      mode: :browse,
      project_id: project.id,
      policy: GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance,
    )

    expect(result).to eq(redacted_row(open_destination_client.id))
  end

  it 'redacts a restricted client even when the given policy allows PII' do
    result = redactor.redact_pii_in_row(
      restricted_row,
      headers: headers,
      user: user,
      mode: :browse,
      policy: GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance,
    )

    expect(result).to eq(redacted_row(restricted_destination_client.id))
  end

  context 'when downloading with a given policy' do
    after { GrdaWarehouse::Config.invalidate_cache }

    def download_with_allow_policy(include_pii:)
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: include_pii)
      GrdaWarehouse::Config.invalidate_cache
      redactor.redact_pii_in_row(
        open_row,
        headers: headers,
        user: user,
        mode: :download,
        policy: GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance,
      )
    end

    it 'redacts PII when include_pii_in_detail_downloads is off' do
      expect(download_with_allow_policy(include_pii: false)).to eq(redacted_row(open_destination_client.id))
    end

    it 'shows PII the policy allows when include_pii_in_detail_downloads is on' do
      expect(download_with_allow_policy(include_pii: true)).to eq([open_destination_client.id, 'Open', 'Doe', Date.new(1985, 6, 15), '987-65-4321'])
    end
  end
end
