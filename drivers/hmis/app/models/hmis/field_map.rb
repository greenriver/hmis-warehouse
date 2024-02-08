###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::FieldMap
  BASE_NULL_VALUES = [
    {
      key: :client_doesn_t_know,
      value: 8,
      desc: 'Client doesn\'t know',
      null: true,
    },
    {
      key: :client_prefers_not_to_answer,
      value: 9,
      desc: 'Client prefers not to answer',
      null: true,
    },
    {
      key: :data_not_collected,
      value: 99,
      desc: 'Data not collected',
      null: true,
    },
  ].freeze

  attr_reader :members, :base_members, :null_members

  def initialize(members, include_base_null: false)
    @base_members = members.reject { |v| v[:null] }
    @null_members = members.select { |v| v[:null] }
    @null_members = [*@null_members, *BASE_NULL_VALUES] if include_base_null
    @members = [*@base_members, *@null_members]
  end

  def lookup(**input_hash)
    @members.find { |hash| hash.slice(*input_hash.keys) == input_hash }
  end

  def values
    @members.pluck(:value).uniq
  end

  def keys
    @members.pluck(:key).uniq
  end

  def base_values
    @base_members.pluck(:value).uniq
  end

  def base_keys
    @base_members.pluck(:value).uniq
  end

  def base_member?(key: nil, value: nil)
    @base_members.any? { |member| member[:key] == key || member[:value] == value }
  end

  def null_member?(key: nil, value: nil)
    @null_members.any? { |member| member[:key] == key || member[:value] == value }
  end
end
