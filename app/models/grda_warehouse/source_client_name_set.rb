###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# SourceClientNameSet aggregates client names from multiple source clients.
# It provides a unified interface for iterating over all valid client names.
#
# @example Basic usage
#   name_set = SourceClientNameSet.new(
#     source_clients: [source_client1, source_client2],
#     user: current_user
#   )
#   name_set.each { |name| puts name.value }
#
module GrdaWarehouse
  class SourceClientNameSet
    include Enumerable

    SourceClientName = Struct.new(:ds_name, :ds_id, :value, keyword_init: true) do
      def to_str = value
      def to_s = value
    end
    private_constant :SourceClientName

    def initialize(source_clients:, user:)
      @names = source_clients.map do |client|
        SourceClientName.new(
          ds_name: client.data_source.short_name,
          ds_id: client.data_source.id,
          value: client.pii_provider(user: user).full_name,
        )
      end

      @names.reject! { |n| n.value.blank? }
      @names.uniq!
    end

    def each(&block)
      @names.each(&block)
    end

    def +(other)
      set = dup
      set.instance_variable_set(:@names, (@names + other.to_a).uniq)
      set
    end

    def to_a
      @names.dup
    end
  end
end
