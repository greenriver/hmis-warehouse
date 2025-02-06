# Provides view-optimized access to source client data for destination clients.
# Handles both efficient data loading and formatted output for views, reducing
# N+1 queries while providing convenient access to client information.
#
class GrdaWarehouse::SourceClientViewAccessor
  def inspect
    object_id
  end

  # @param user [User] The current user accessing the client data
  # @param clients [Array<DestinationClient>] Collection of destination clients to load data for
  # @raise [RuntimeError] if a destination client reference is missing
  def initialize(user:, clients:)
    @user = user
    @source_clients = {}

    preload_source_clients(clients)
  end

  # Retrieves source clients for a given destination client
  # @param client [DestinationClient] The destination client to look up
  # @return [Array<HudClient>] Array of source client records associated with the destination client
  def source_clients(client)
    @source_clients[client.id] || []
  end

  # @param client [DestinationClient] The destination client to get names for
  # @param health [Boolean] Whether to include patient name
  def client_names(client)
    GrdaWarehouse::SourceClientNameSet.new(
      destination_client: client,
      source_clients: source_clients(client),
      user: @user,
    )
  end

  protected

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

      @source_clients[key] ||= []
      @source_clients[key] << client
    end
  end
end
