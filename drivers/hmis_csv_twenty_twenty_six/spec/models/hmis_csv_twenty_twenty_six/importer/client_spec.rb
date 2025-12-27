# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::Client, type: :model do
  it 'has HispanicLatinao as an alias for HispanicLatinaeo' do
    # HispanicLatinaeo exists in 2026
    expect(described_class.attribute_names).to include('HispanicLatinaeo')

    client = described_class.new(HispanicLatinaeo: 1)
    expect(client.HispanicLatinao).to eq(1)
    client.HispanicLatinao = 2
    expect(client.HispanicLatinaeo).to eq(2)
  end
end
