###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Restricts a destination client from the warehouse. The restriction is an Hmis::RestrictedRecord
# on the destination id, typed as Hmis::Hud::Client (both classes read the Client table).
# GrdaWarehouse::HiddenClients and analytics.client_piis already hide the whole identity for a row
# on a destination id. HMIS only checks rows on its own client ids, so this does not restrict
# the client in HMIS. Rows on source clients belong to HMIS and are never removed here.
class DestinationClientRestriction
  def initialize(client)
    raise ArgumentError, 'Must be a destination client' unless client.destination?(strict: true)

    @client = client
  end

  def restricted_in_warehouse?
    restricted_records.where(restrictable_id: @client.id).exists?
  end

  def restricted_in_hmis?
    restricted_records.where(restrictable_id: @client.source_client_ids).exists?
  end

  def restricted?
    restricted_in_warehouse? || restricted_in_hmis?
  end

  # @param user [User]
  def restrict!(user:)
    Hmis::RestrictedRecord.mark!(restrictable, user: Hmis::User.find(user.id))
    @client.clear_view_cache
  end

  # @return [Boolean] whether a warehouse row was removed
  def unrestrict!
    removed = Hmis::RestrictedRecord.unmark!(restrictable).present?
    @client.clear_view_cache
    removed
  end

  # A create version is a restriction and a destroy is its removal.
  # @return [ActiveRecord::Relation<GrdaWarehouse::Version>]
  def versions
    GrdaWarehouse.paper_trail_versions.
      where(item_type: Hmis::RestrictedRecord.name, client_id: [@client.id] + @client.source_client_ids).
      order(created_at: :desc, id: :desc)
  end

  private def restrictable
    Hmis::Hud::Client.find(@client.id)
  end

  private def restricted_records
    Hmis::RestrictedRecord.for_clients
  end
end
