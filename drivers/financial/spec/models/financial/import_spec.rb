###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Financial::Import, type: :model do
  describe '#expand' do
    include_context 'a zip file to extract'

    # The names fetch_and_push then looks for as File.join(extract_path, name).
    let(:zip_entries) do
      {
        'Clients.csv' => "ClientID\n1\n",
        'Providers.csv' => "ProviderID\n1\n",
        'Transactions.csv' => "TransactionID\n1\n",
      }
    end
    let(:nested_entry_name) { 'nested/Adjustments.csv' }

    # #expand takes its destination as an argument and touches no other state,
    # so an unsaved record is enough.
    let(:import) { described_class.new }

    def extract!
      import.send(:expand, file_path: zip_source, extract_path: destination_dir)
    end

    include_examples 'extracts entries into the destination directory'
  end
end
