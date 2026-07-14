###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Characterization specs for the ArelHelper named-function builders (nf/cl/ct/greatest)
# and qt. These pin the SQL these helpers generate so that an Arel/ActiveRecord major
# upgrade (e.g. Rails 8, which changed the Arel NamedFunction constructor arity and
# dropped its alias argument) is caught here rather than at runtime on a report page.
RSpec.describe 'ArelHelper named functions' do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :arel_helper_fn_specs, force: true do |t|
        t.string :name
        t.string :other
        t.integer :amount
      end
    end

    class ArelHelperFnThing < ActiveRecord::Base
      self.table_name = 'arel_helper_fn_specs'
      include ArelHelper
    end
  end

  after(:all) do
    Object.send(:remove_const, :ArelHelperFnThing)
    ActiveRecord::Schema.define do
      drop_table :arel_helper_fn_specs, force: true
    end
  end

  let(:klass) { ArelHelperFnThing }
  let(:t) { ArelHelperFnThing.arel_table }

  describe '.qt' do
    it 'quotes a bare string' do
      expect(klass.qt('a').to_sql).to eq("'a'")
    end

    it 'quotes a bare integer' do
      expect(klass.qt(5).to_sql).to eq('5')
    end

    it 'passes an Arel attribute through unchanged' do
      attr = t[:name]
      expect(klass.qt(attr)).to be(attr)
    end
  end

  describe '.nf' do
    it 'builds a no-argument function' do
      expect(klass.nf('NOW').to_sql).to eq('NOW()')
    end

    it 'builds a function over columns and quoted literals' do
      expect(klass.nf('COALESCE', [t[:amount], 0]).to_sql).
        to eq('COALESCE("arel_helper_fn_specs"."amount", 0)')
    end

    # The regression that broke boston-cas on Rails 8: an aliased named function.
    it 'applies an alias to the function' do
      expect(klass.nf('COALESCE', [t[:amount], 0], 'the_alias').to_sql).
        to eq('COALESCE("arel_helper_fn_specs"."amount", 0) AS the_alias')
    end

    it 'raises when args is not an Array' do
      expect { klass.nf('X', 'notarray') }.to raise_error(RuntimeError, 'args must be an Array')
    end
  end

  describe '.cl' do
    it 'builds a COALESCE function' do
      expect(klass.cl(t[:amount], 0).to_sql).
        to eq('COALESCE("arel_helper_fn_specs"."amount", 0)')
    end
  end

  describe '.ct' do
    it 'builds a CONCAT function' do
      expect(klass.ct(t[:name], t[:other]).to_sql).
        to eq('CONCAT("arel_helper_fn_specs"."name", "arel_helper_fn_specs"."other")')
    end
  end

  describe '.greatest' do
    it 'builds a GREATEST function' do
      expect(klass.greatest(t[:amount], 1).to_sql).
        to eq('GREATEST("arel_helper_fn_specs"."amount", 1)')
    end
  end
end
