###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Types::BaseField do
  it 'raises an ArgumentError when given both permissions and authorize_with' do
    expect do
      described_class.new(name: :example, type: String, null: true, permissions: :can_view_clients, authorize_with: ->(_user, _object) { true })
    end.to raise_error(ArgumentError, "don't use permissions and authorize_with")
  end
end
