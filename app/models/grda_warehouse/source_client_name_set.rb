# SourceClientNameSet aggregates client names from multiple data sources, including
# both source clients and patient health records. It provides a unified interface
# for iterating over all valid client names.
#
# @example Basic usage
#   name_set = SourceClientNameSet.new(
#     destination_client: client,
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
    end
    private_constant :SourceClientName

    def initialize(destination_client:, source_clients:, user:)
      @names = source_clients.map do |client|
        SourceClientName.new(
          ds_name: client.data_source&.short_name,
          ds_id: client.data_source&.id,
          value: client.pii_provider(user: user).full_name,
        )
      end

      patient = destination_client.patient
      if patient && source_clients.none? { |sc| sc.data_source&.authoritative_type == 'health' }
        @names << SourceClientName.new(
          ds_name: 'Health',
          ds_id: GrdaWarehouse::DataSource.health_authoritative_id,
          value: patient.pii_provider(user: user).brief_name,
        )
      end
      @names.uniq!
    end

    def each(&block)
      @names.each(&block)
    end
  end
end
