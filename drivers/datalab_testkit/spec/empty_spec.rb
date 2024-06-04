require 'rails_helper'
require_relative 'models/datalab_testkit_context'

RSpec.describe 'Empty test to load fixpoints' do
  include_context 'datalab testkit context'
  before(:all) do
    setup
  end

  after(:all) do
    cleanup
  end

  it 'Always Passes' do
    expect(true).to be true
  end
end
