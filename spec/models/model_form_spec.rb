###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelForm, type: :model do
  def form_class(parent = described_class, &body)
    Class.new(parent) do
      def self.name = 'TestForm'

      class_eval(&body)
    end
  end

  describe 'casting' do
    let(:klass) do
      form_class do
        attribute :str, String
        attribute :int, Integer
        attribute :date, Date
        attribute :bool, ModelForm::Boolean
        attribute :sym, Symbol
        attribute :list, Array
        attribute :strings, Array[String]
        attribute :untyped
      end
    end

    def cast(name, value)
      klass.new(name => value).public_send(name)
    end

    def object_responding_to(method, value)
      Object.new.tap { |object| object.define_singleton_method(method) { value } }
    end

    it 'casts String from scalars and to_str, leaving other values unchanged' do
      expect(cast(:str, true)).to eql('true')
      expect(cast(:str, false)).to eql('false')
      expect(cast(:str, 5)).to eql('5')
      expect(cast(:str, :abc)).to eql('abc')
      expect(cast(:str, object_responding_to(:to_str, 'converted'))).to eql('converted')
      expect(cast(:str, ['a'])).to eql(['a'])
      expect(cast(:str, nil)).to be_nil
    end

    it 'casts Integer from integer and numeric strings, leaving other strings unchanged' do
      expect(cast(:int, '12')).to eql(12)
      expect(cast(:int, '-3')).to eql(-3)
      expect(cast(:int, '+4')).to eql(4)
      expect(cast(:int, '1.5')).to eql(1)
      expect(cast(:int, '1e3')).to eql(1000)
      expect(cast(:int, '.5')).to eql(0)
      expect(cast(:int, 2.9)).to eql(2)
      expect(cast(:int, Time.utc(2025, 1, 1))).to eql(1_735_689_600)
      expect(cast(:int, object_responding_to(:to_int, 7))).to eql(7)
      expect(cast(:int, '')).to eql('')
      expect(cast(:int, '12abc')).to eql('12abc')
      expect(cast(:int, ' 7 ')).to eql(' 7 ')
      expect(cast(:int, '1,000')).to eql('1,000')
      expect(cast(:int, true)).to be(true)
    end

    it 'casts Date from parseable strings, dates and times, leaving other values unchanged' do
      expect(cast(:date, '2025-01-01')).to eql(Date.new(2025, 1, 1))
      expect(cast(:date, Date.new(2025, 1, 2))).to eql(Date.new(2025, 1, 2))
      expect(cast(:date, Time.utc(2025, 3, 4, 5))).to eql(Date.new(2025, 3, 4))
      expect(cast(:date, DateTime.new(2025, 3, 4, 5, 6))).to be_an_instance_of(Date).and eq(Date.new(2025, 3, 4))
      expect(cast(:date, '')).to eql('')
      expect(cast(:date, '2025-13-45')).to eql('2025-13-45')
      expect(cast(:date, 5)).to eql(5)
    end

    it 'casts Boolean from true/false words and 0/1 only' do
      expect(cast(:bool, 'YES')).to be(true)
      expect(cast(:bool, 'no')).to be(false)
      ['1', 'true', 't', 'y', 'on'].each { |word| expect(cast(:bool, word)).to be(true), word }
      ['0', 'false', 'off'].each { |word| expect(cast(:bool, word)).to be(false), word }
      expect(cast(:bool, true)).to be(true)
      expect(cast(:bool, false)).to be(false)
      expect(cast(:bool, 1)).to be(true)
      expect(cast(:bool, 0)).to be(false)
      expect(cast(:bool, '')).to eql('')
      expect(cast(:bool, 5)).to eql(5)
      expect(cast(:bool, 1.0)).to eql(1.0)
    end

    it 'casts Symbol from strings only' do
      expect(cast(:sym, 'abc')).to eql(:abc)
      expect(cast(:sym, '')).to eql(:'')
      expect(cast(:sym, 5)).to eql(5)
    end

    it 'casts Array with Kernel#Array' do
      expect(cast(:list, nil)).to eql([])
      expect(cast(:list, 'x')).to eql(['x'])
      expect(cast(:list, ['a', 1])).to eql(['a', 1])
      expect(cast(:list, { k: 'v' })).to eql([[:k, 'v']])
    end

    it 'casts Array to a copy, so changing the result leaves the assigned array alone' do
      assigned = ['a']
      cast(:list, assigned) << 'b'

      expect(assigned).to eq(['a'])
    end

    it 'casts Array[String] members to strings, keeping nil members' do
      expect(cast(:strings, [1, :x, nil])).to eql(['1', 'x', nil])
      expect(cast(:strings, nil)).to eql([])
    end

    it 'passes values through for untyped attributes' do
      expect(cast(:untyped, :abc)).to eql(:abc)
    end

    it 'raises when an attribute or Array member is declared with an unsupported class' do
      expect { form_class { attribute :rate, Float } }.to raise_error(ArgumentError, /Float/)
      expect { form_class { attribute :paths, Array[Pathname] } }.to raise_error(ArgumentError, /Pathname/)
    end

    it 'exposes declared attribute names as strings' do
      expect(klass.attribute_names).to eq(['str', 'int', 'date', 'bool', 'sym', 'list', 'strings', 'untyped'])
    end
  end

  describe 'casting BigDecimal, date-part Hash, and TimeWithZone values' do
    let(:klass) do
      form_class do
        attribute :str, String
        attribute :date, Date
      end
    end

    it 'casts BigDecimal to a plain decimal string' do
      expect(klass.new(str: BigDecimal('1234567.5')).str).to eql('1234567.5')
    end

    it 'builds a Date from year, month and day hash parts' do
      expect(klass.new(date: { year: '2025', month: 3, day: '4' }).date).to eql(Date.new(2025, 3, 4))
    end

    it 'fills missing hash parts from the current date' do
      travel_to(Time.zone.local(2026, 5, 6, 12)) do
        expect(klass.new(date: { year: 2025 }).date).to eql(Date.new(2025, 5, 6))
      end
    end

    it 'ignores string-keyed hash parts, building the current date' do
      travel_to(Time.zone.local(2026, 5, 6, 12)) do
        expect(klass.new(date: { 'year' => 2025, 'month' => 1, 'day' => 2 }).date).to eql(Date.new(2026, 5, 6))
      end
    end

    it 'raises Date::Error for hash parts that describe an impossible date' do
      expect { klass.new(date: { year: 2025, month: 2, day: 31 }).date }.to raise_error(Date::Error)
    end

    it 'passes a TimeWithZone through unchanged' do
      time = Time.zone.local(2025, 3, 4, 5)

      expect(klass.new(str: time, date: time).attributes).to eq(str: time, date: time)
    end
  end

  describe 'static defaults' do
    let(:klass) do
      form_class do
        attribute :tags, nil, default: ['a']
        attribute :frozen_name, String, default: 'fixed'
        attribute :count, Integer, default: '7'
        attribute :items, Array
      end
    end

    it 'gives each instance its own copy of the default' do
      first = klass.new
      second = klass.new
      first.tags << 'b'

      expect(second.tags).to eq(['a'])
    end

    it 'keeps a frozen default frozen' do
      expect(klass.new.frozen_name).to be_frozen
    end

    it 'casts the default and defaults Array attributes to an empty array' do
      expect(klass.new.count).to eql(7)
      expect(klass.new.items).to eql([])
    end
  end

  describe 'eager defaults' do
    let(:calls) { [] }
    let(:klass) do
      log = calls
      form_class do
        attribute :route, String, default: 'one'
        attribute :step, String, default: ->(r, _attr) {
          log << :step
          "#{r.route}-first"
        }
      end
    end

    it 'runs after mass assignment and sees assigned values' do
      expect(klass.new(route: 'two').step).to eq('two-first')
    end

    it 'runs once during initialize' do
      form = klass.new
      expect(calls).to eq([:step])

      form.step
      expect(calls).to eq([:step])
    end

    it 'is skipped when the attribute was assigned, including nil' do
      expect(klass.new(step: nil).step).to be_nil
      expect(calls).to be_empty
    end
  end

  describe 'lazy defaults' do
    let(:calls) { [] }
    let(:klass) do
      log = calls
      form_class do
        attribute :base, String, default: 'b'
        attribute :title, String, lazy: true, default: ->(r, _attr) {
          log << :title
          "#{r.base}!"
        }
      end
    end

    it 'computes the default on first read only' do
      form = klass.new
      expect(calls).to be_empty

      2.times { form.title }
      expect(calls).to eq([:title])
      expect(form.title).to eq('b!')
    end

    it 'keeps nil assigned before the first read' do
      form = klass.new
      form.title = nil

      expect(form.title).to be_nil
      expect(calls).to be_empty
    end

    it 'keeps the resolved value when its inputs change later' do
      form = klass.new
      form.title
      form.base = 'changed'

      expect(form.title).to eq('b!')
    end

    it 'leaves the original unchanged when a dup is assigned' do
      original = klass.new
      copy = original.dup
      copy.title = 'copy'

      expect(copy.title).to eq('copy')
      expect(original.title).to eq('b!')
    end
  end

  describe 'dup' do
    let(:klass) do
      form_class do
        attribute :record
      end
    end

    it 'shares an untyped value with the copy after the value was read' do
      record = Object.new
      original = klass.new(record: record)
      original.record

      expect(original.dup.record).to equal(record)
    end
  end

  describe 'symbol defaults' do
    let(:klass) do
      form_class do
        attribute :label, String, lazy: true, default: :missing_method
        attribute :kind, Symbol, default: :missing_method
        attribute :computed, String, default: :compute

        private def compute = 'from method'
      end
    end

    it 'uses the symbol cast to the attribute type when no such method exists' do
      expect(klass.new.label).to eql('missing_method')
      expect(klass.new.kind).to eql(:missing_method)
    end

    it 'calls the named method, including a private one' do
      expect(klass.new.computed).to eq('from method')
    end
  end

  describe 'custom writers' do
    let(:klass) do
      form_class do
        attr_reader :writes

        attribute :code, Integer, default: '7'

        def code=(value)
          (@writes ||= []) << value
          super
        end
      end
    end

    it 'skip custom writers for defaults, which are still cast' do
      form = klass.new

      expect(form.code).to eql(7)
      expect(form.writes).to be_nil
    end

    it 'are used for mass assignment' do
      form = klass.new(code: '9')

      expect(form.code).to eql(9)
      expect(form.writes).to eq(['9'])
    end
  end

  describe 'subclass redeclaring an attribute' do
    let(:parent) { form_class { attribute :scope, String, default: 'parent' } }
    let(:child) { form_class(parent) { attribute :scope, String, default: 'child' } }

    it 'uses its own default and leaves the parent default unchanged' do
      expect(child.new.scope).to eq('child')
      expect(parent.new.scope).to eq('parent')
    end
  end

  describe 'sibling subclasses redeclaring an attribute' do
    let(:parent) { form_class { attribute :scope, String, default: 'parent' } }
    let(:first) { form_class(parent) { attribute :scope, String, default: 'first' } }
    let(:second) { form_class(parent) { attribute :scope, String, default: 'second' } }

    it 'keeps a separate default for each sibling and the parent' do
      expect([first.new.scope, second.new.scope, parent.new.scope]).to eq(['first', 'second', 'parent'])
    end
  end

  describe 'freezing' do
    let(:klass) do
      form_class do
        attribute :base, String, default: 'b'
        attribute :title, String, lazy: true, default: ->(r, _attr) { "#{r.base}!" }
        attribute :note, String, lazy: true, default: 'n'
      end
    end

    it 'returns lazy defaults from a frozen instance' do
      form = klass.new(note: 'given').freeze

      expect(form).to be_frozen
      expect(form.title).to eq('b!')
      expect(form.note).to eq('given')
    end
  end

  describe '#attributes' do
    let(:klass) do
      form_class do
        attribute :start, String, lazy: true, default: ->(_r, _attr) { 'lazy' }
        attribute :count, Integer, default: 1

        def start = "#{super}!"
      end
    end

    it 'returns reader output under symbol keys in declaration order' do
      form = klass.new

      expect(form.attributes).to eq({ start: 'lazy!', count: 1 })
      expect(form.attributes.keys).to eq([:start, :count])
      expect(form.to_h).to eq(form.attributes)
      expect(form.to_hash).to eq(form.attributes)
    end
  end

  describe 'method lookup' do
    let(:calls) { [] }
    let(:klass) do
      log = calls
      form_class do
        attribute :title, String, lazy: true, default: ->(_r, _attr) {
          log << :title
          't'
        }
      end
    end

    it 'answers respond_to? and flatten without reading attributes' do
      form = klass.new

      expect(form.respond_to?(:unknown)).to be(false)
      expect(form.respond_to?(:title)).to be(true)
      expect([form].flatten).to eq([form])
      expect(calls).to be_empty
    end

    it 'rejects unknown keys on mass assignment' do
      expect { klass.new(unknown: 1) }.to raise_error(ActiveModel::UnknownAttributeError)
    end
  end

  describe 'YAML' do
    let(:klass) do
      form_class do
        attr_accessor :extra

        attribute :name, String
        attribute :count, Integer
        attribute :title, String, lazy: true, default: ->(r, _attr) { "#{r.name} title" }
      end
    end

    before { stub_const('TestForm', klass) }

    it 'round-trips values without ActiveModel tags' do
      form = TestForm.new(name: 'n', count: '3')
      form.extra = 'plain'
      yaml = YAML.dump(form)
      loaded = YAML.unsafe_load(yaml)

      expect(yaml).not_to include('ActiveModel')
      expect([loaded.name, loaded.count, loaded.extra]).to eq(['n', 3, 'plain'])
    end

    it 'stores an unread lazy default as unset so it is computed after loading' do
      form = TestForm.new(name: 'before')
      loaded = YAML.unsafe_load(YAML.dump(form))
      loaded.name = 'after'

      expect(loaded.title).to eq('after title')
    end

    it 'loads a flat instance-variable document, casting attributes and keeping other keys as ivars' do
      loaded = YAML.unsafe_load(<<~YAML)
        --- !ruby/object:TestForm
        name: stored
        count: '5'
        cohort_column: kept
      YAML

      expect(loaded.name).to eq('stored')
      expect(loaded.count).to eql(5)
      expect(loaded.title).to eq('stored title')
      expect(loaded.instance_variable_get(:@cohort_column)).to eq('kept')
    end

    it 'ignores an attributes key so declared attributes still read their values' do
      loaded = YAML.unsafe_load(<<~YAML)
        --- !ruby/object:TestForm
        attributes: replaced
        name: stored
      YAML

      expect(loaded.name).to eq('stored')
    end
  end
end
