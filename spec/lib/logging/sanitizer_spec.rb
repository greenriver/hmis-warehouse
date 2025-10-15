# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Logging::Sanitizer do
  subject(:sanitizer) { described_class.new(**overrides) }

  let(:overrides) { {} }

  describe '#call' do
    context 'when value is nil' do
      it 'returns nil' do
        expect(sanitizer.call(nil)).to be_nil
      end
    end

    context 'when value is false' do
      it 'preserves false' do
        expect(sanitizer.call(false)).to be(false)
      end
    end
  end

  describe 'string sanitization' do
    it 'removes control characters' do
      sanitized = sanitizer.call("he\u0001llo")
      expect(sanitized).to eq('hello')
    end

    it 'truncates strings over the limit' do
      overrides[:max_string_length] = 5

      sanitized = sanitizer.call('a' * 50)

      expect(sanitized).to eq('...[TRUNCATED]')
    end
  end

  describe 'array sanitization' do
    it 'limits items and appends count of remaining items' do
      overrides[:max_array_items] = 2

      sanitized = sanitizer.call(['a', 'b', 'c'])

      expect(sanitized).to eq(['a', 'b', '...[1 more items]'])
    end

    it 'honors max depth when nested hashes exceed depth' do
      overrides[:max_depth] = 2

      sanitized = sanitizer.call([{ foo: { bar: 'baz' } }, { fiz: 'bang' }])

      expect(sanitized).to eq([{ foo: '[MAX_DEPTH]' }, { fiz: 'bang' }])
    end
  end

  describe 'hash sanitization' do
    it 'returns a hash with sanitized values' do
      sanitized = sanitizer.call({ foo: "bar\u0001" })

      expect(sanitized).to eq({ foo: 'bar' })
    end

    it 'enforces max depth' do
      overrides[:max_depth] = 1

      sanitized = sanitizer.call({ foo: { bar: 'baz' } })

      expect(sanitized).to eq({ foo: '[MAX_DEPTH]' })
    end

    it 'truncates extra keys and adds _truncated metadata' do
      overrides[:max_hash_items] = 1

      sanitized = sanitizer.call({ first: 'one', second: 'two' })

      expect(sanitized).to eq({ first: 'one', _truncated: '1 items hidden' })
    end

    it 'preserves hash order for deterministic logging' do
      ordered_hash = {}
      ordered_hash[:first] = 'one'
      ordered_hash[:second] = 'two'

      sanitized = sanitizer.call(ordered_hash)

      expect(sanitized.keys).to eq([:first, :second])
    end
  end
end
