# frozen_string_literal: true

# The SourceClientViewAccessor implements view-specific optimizations to prevent N+1 queries
# when accessing and authorizing source clients. It is most useful in a list context, such as
# when rendering an index page.
#
# The class manages a cache of authorized source client records, grouped by destination client.
#
# @example Batch preloading for multiple clients
#   accessor = GrdaWarehouse::SourceClientViewAccessor.new(user: current_user)
#   accessor.preload_searchable_clients(destination_clients)
#   destination_clients.each do |client|
#     source_clients = accessor.searchable_clients(client)
#     # Process source clients...
#   end
#
class GrdaWarehouse::SourceClientViewAccessor
  # Internal cache for source clients, keyed by destination client id
  # Used to batch and memoize source client lookups for a given user and permission method
  # @private
  class Cache
    # @param user [User] The user for permission checks
    # @param block [Proc] Block that receives an array of source_client_ids and returns source client records
    #   Example: ->(ids) { ArbiterClass.method(user, client_ids: ids) }
    def initialize(user, &block)
      @user = user
      @block = block
      @cache = {}
    end

    # Returns cached source clients for a destination client, preloading if needed
    # @param client [DestinationClient] The destination client
    # @return [Array<SourceClient>] Array of source clients
    def clients(client)
      key = client.id
      preload([client]) unless @cache.key?(key)
      @cache[key] ||= []
    end

    # Preloads and caches source clients for a batch of destination clients
    # @param clients [Array<DestinationClient>] Destination clients to preload
    # @return [Boolean, nil] true if preloaded, nil if no source clients found
    def preload(clients)
      destination_client_ids = clients.map(&:id)
      source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: destination_client_ids).pluck(:source_id)
      return if source_client_ids.empty?

      source_clients = @block.call(source_client_ids)
      source_clients.each do |client|
        key = client.destination_client&.id
        raise "Source client #{client.id} references invalid destination client" unless key

        @cache[key] ||= []
        @cache[key] << client
      end
      true
    end
  end

  # Overrides the default inspect method to prevent memory-intensive string
  # generation when the object contains many cached clients
  def inspect
    object_id
  end

  # @param user [User] The authenticated for permissions checks
  def initialize(user:)
    @user = user
    arbiter = GrdaWarehouse::Hud::Client.arbiter(@user)
    @searchable_cache = Cache.new(user) do |ids|
      arbiter.clients_source_searchable_to(@user, client_ids: ids).preload(:destination_client, :data_source, :patient)
    end
    @viewable_cache = Cache.new(user) do |ids|
      arbiter.clients_source_visible_to(@user, client_ids: ids).preload(:destination_client, :data_source, :patient)
    end
  end

  # Retrieves all searchable source clients associated with a given destination client, filtered
  # to only those searchable by the current user
  #
  # @param client [DestinationClient] The destination client whose source records
  #   should be retrieved
  # @return [Array<SourceClient>] Array of associated source client records
  # @note Automatically triggers preloading if the client hasn't been cached
  def searchable_clients(client)
    @searchable_cache.clients(client)
  end

  # Retrieves all viewable source clients associated with a given destination client, filtered
  # to only those searchable by the current user
  #
  # @param client [DestinationClient] The destination client whose source records
  #   should be retrieved
  # @return [Array<SourceClient>] Array of associated source client records
  # @note Automatically triggers preloading if the client hasn't been cached
  def viewable_clients(client)
    @viewable_cache.clients(client)
  end

  # Name set object containing aliases from the source clients associated with the
  # given destination client, filtered to only those searchable by the current user
  #
  # @param client [DestinationClient] The destination client whose names
  #   should be retrieved
  # @return [GrdaWarehouse::SourceClientNameSet] Object containing all name
  #   variations from source records
  def searchable_client_names(client)
    GrdaWarehouse::SourceClientNameSet.new(
      destination_client: client,
      source_clients: searchable_clients(client),
      user: @user,
    )
  end

  def viewable_client_names(client)
    GrdaWarehouse::SourceClientNameSet.new(
      destination_client: client,
      source_clients: viewable_clients(client),
      user: @user,
    )
  end

  # Preloads and caches source client data for a batch of destination clients to
  # optimize subsequent access
  #
  # @param clients [Array<DestinationClient>] Array of destination clients
  #   whose source records should be preloaded
  # @return [Boolean] true if preloading was performed, false if no source
  #   clients were found
  def preload_searchable_clients(clients)
    @searchable_cache.preload(clients)
  end

  # Preloads and caches source client data for a batch of destination clients to
  # optimize subsequent access
  #
  # @param clients [Array<DestinationClient>] Array of destination clients
  #   whose source records should be preloaded
  # @return [Boolean] true if preloading was performed, false if no source
  #   clients were found
  def preload_viewable_clients(clients)
    @viewable_cache.preload(clients)
  end
end
