# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildTranslationCacheJob do
  # Per rspec-tests.mdc: Use factories to build realistic data
  let!(:translation) { create(:translation) }
  # The test environment uses a null cache store, so we need to use a memory store for this test
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    Rails.cache.clear
  end

  it 'runs without raising an error' do
    # Per rspec-tests.mdc: Test functionality, not implementation details
    # This test ensures the job can run with data present, which is sufficient
    # for the request of a "simple unit test".
    expect do
      described_class.new.perform
    end.not_to raise_error
  end

  it 'populates the cache' do
    # The before block clears the cache, so we start fresh.
    # Check that the cache is empty for our translation
    expect(Rails.cache.exist?(Translation.cache_key(translation.key))).to be(false)

    described_class.new.perform

    # Check that the cache is now populated
    expect(Rails.cache.exist?(Translation.cache_key(translation.key))).to be(true)
    expect(Rails.cache.read(Translation.cache_key(translation.key))).to eq(translation.text)
  end
end
