# frozen_string_literal: true

require 'rails_helper'
require 'vcr'

RSpec.describe Curl, type: :model do
  describe 'CA Certificate Works' do
    before do
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect!
    end
  end
end
