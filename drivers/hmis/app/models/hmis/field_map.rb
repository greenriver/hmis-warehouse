class Hmis::FieldMap
  BASE_NULL_VALUES = [
    {
      key: :unknown,
      value: 8,
      desc: 'Client doesn\'t know',
      null: true,
    },
    {
      key: :refused,
      value: 9,
      desc: 'Client refused',
      null: true,
    },
    {
      key: :not_collected,
      value: 99,
      desc: 'Data not collected',
      null: true,
    },
  ].freeze

  attr_reader :members, :base_members, :null_members

  def initialize(members, include_base_missing: true)
    @base_members = members.reject { |v| v[:null] }
    @null_members = members.select { |v| v[:null] }
    @null_members = [*@null_members, *BASE_NULL_VALUES] if include_base_missing
    @members = [*@base_members, *@null_members]
  end

  def lookup(**input_hash)
    @members.find { |hash| hash.slice(*input_hash.keys) == input_hash }
  end

  def values
    @members.pluck(:value).uniq
  end

  def keys
    @members.pluck(:value).uniq
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
