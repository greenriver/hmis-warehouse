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
  end
end
