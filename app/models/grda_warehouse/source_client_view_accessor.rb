# Provides view-optimized access to source client data for destination clients.
# Handles both efficient data loading and formatted output for views, reducing
# N+1 queries while providing convenient access to client information.
#
class GrdaWarehouse::SourceClientViewAccessor
  # override inspect to prevent clutter exceptions
  def inspect
    object_id
  end

  # @param user [User] The current user accessing the client data
  def initialize(user:)
    @user = user
    @searchable_clients = {}
  end

  # Retrieves source clients for a given destination client
  # @param client [DestinationClient] The destination client to look up
  # @return [Array<SourceClient>] Array of source client records associated with the destination client
  def searchable_clients(client)
    key = client.id
    preload_source_clients([client]) unless @searchable_clients.key?(key)
    @searchable_clients[key] || []
  end

  # @param client [DestinationClient] The destination client to get names for
  def searchable_client_names(client)
    GrdaWarehouse::SourceClientNameSet.new(
      destination_client: client,
      source_clients: searchable_clients(client),
      user: @user,
    )
  end

  # @param client [Array<DestinationClient>] Array of destination clients to preload for later access
  def preload_source_clients(clients)
    destination_client_ids = clients.map(&:id)
    source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: destination_client_ids).pluck(:source_id)

    return if source_client_ids.empty?

    clients = GrdaWarehouse::Hud::Client.arbiter(@user).
      clients_source_searchable_to(@user, client_ids: source_client_ids).
      preload(:destination_client, :data_source, :patient)

    clients.each do |client|
      key = client.destination_client&.id
      raise unless key

      @searchable_clients[key] ||= []
      @searchable_clients[key] << client
    end
    true
  end
end
