# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ArelHelper.one_for_column' do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :arel_helper_specs, force: true do |t|
        t.string :identifier
        t.integer :version
        t.datetime :deleted_at
        t.datetime :discarded_at
      end
      create_table :arel_helper_owners, force: true do |t|
        t.string :thing_identifier
      end
    end

    class NonParanoidThing < ActiveRecord::Base
      self.table_name = 'arel_helper_specs'
      include ArelHelper
    end

    class ParanoidThing < ActiveRecord::Base
      self.table_name = 'arel_helper_specs'
      include ArelHelper
      acts_as_paranoid
    end

    class ParanoidCustomColThing < ActiveRecord::Base
      self.table_name = 'arel_helper_specs'
      include ArelHelper
      acts_as_paranoid column: :discarded_at
    end

    class ThingOwner < ActiveRecord::Base
      self.table_name = 'arel_helper_owners'
      belongs_to :thing,
                 -> { one_for_column([:version], source_arel_table: ParanoidThing.arel_table, group_on: :identifier) },
                 class_name: 'ParanoidThing',
                 foreign_key: :thing_identifier,
                 primary_key: :identifier,
                 optional: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :NonParanoidThing)
    Object.send(:remove_const, :ParanoidThing)
    Object.send(:remove_const, :ParanoidCustomColThing)
    Object.send(:remove_const, :ThingOwner)
    ActiveRecord::Schema.define do
      drop_table :arel_helper_specs, force: true
      drop_table :arel_helper_owners, force: true
    end
  end

  def rows_for(klass, identifier:, versions:, soft_delete: nil)
    versions.each { |v| klass.create!(identifier: identifier, version: v) }
    return unless soft_delete

    return unless klass.respond_to?(:paranoid?) && klass.paranoid?

    col = klass.paranoia_column
    klass.where(identifier: identifier, version: soft_delete).update_all(col => Time.current)
  end

  it 'excludes soft-deleted rows for paranoid models (default deleted_at)' do
    rows_for(ParanoidThing, identifier: 'x', versions: [1, 2], soft_delete: 2)
    rel = ParanoidThing.one_for_column([:version], source_arel_table: ParanoidThing.arel_table, group_on: :identifier)
    expect(rel.where(identifier: 'x').pluck(:version)).to eq([1])
  end

  it 'does not exclude rows for non-paranoid models' do
    rows_for(NonParanoidThing, identifier: 'y', versions: [1, 2])
    rel = NonParanoidThing.one_for_column([:version], source_arel_table: NonParanoidThing.arel_table, group_on: :identifier)
    expect(rel.where(identifier: 'y').pluck(:version)).to eq([2])
  end

  it 'respects custom paranoia_column' do
    rows_for(ParanoidCustomColThing, identifier: 'z', versions: [1, 2], soft_delete: 2)
    rel = ParanoidCustomColThing.one_for_column([:version], source_arel_table: ParanoidCustomColThing.arel_table, group_on: :identifier)
    expect(rel.where(identifier: 'z').pluck(:version)).to eq([1])
  end

  it 'uses provided scope in subquery, but outer relation still respects paranoia (deleted winner yields no rows)' do
    rows_for(ParanoidThing, identifier: 's', versions: [1, 2], soft_delete: 2)
    scope = ParanoidThing.unscoped # intentionally bypass paranoia
    rel = ParanoidThing.one_for_column([:version], source_arel_table: ParanoidThing.arel_table, group_on: :identifier, scope: scope)
    expect(rel.where(identifier: 's').pluck(:version)).to eq([])
  end

  it 'resolves latest non-deleted row via association when highest version is soft-deleted' do
    rows_for(ParanoidThing, identifier: 'edge', versions: [1, 2], soft_delete: 2)
    v1 = ParanoidThing.find_by!(identifier: 'edge', version: 1)
    owner = ThingOwner.create!(thing_identifier: 'edge')
    expect(owner.thing&.id).to eq(v1.id)
  end
end
