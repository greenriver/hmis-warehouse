require 'rails_helper'

RSpec.describe HmisSupplemental::DataSet, type: :model do
  let(:data_set) do
    create(:hmis_supplemental_data_set)
  end

  it 'validates for empty field config' do
    data_set.field_config = <<~JSON
      []
    JSON
    expect(data_set.save).to be(false)
    expect(data_set.errors.full_messages).to eq(['Field config root is invalid: error_type=minItems'])
  end

  it 'validates syntax errors in the config' do
    data_set.field_config = <<~JSON
      [{this won't parse, hopefully}]
    JSON
    expect(data_set.save).to be(false)
    expect(data_set.errors.full_messages).to contain_exactly(
      a_string_matching(/\AField config unexpected token.*/),
    )
  end
end
