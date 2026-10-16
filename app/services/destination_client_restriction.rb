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

  # Removes the row from a destination that a merge left without sources. The client has no
  # restricted_record association, so the row would outlive it. Without sources the client is no
  # longer a destination?(strict: true), so this does not go through new.
  # @param client_id [Integer]
  # @param user [User]
  def self.unrestrict_merged_away!(client_id, user:)
    as_actor(user) { Hmis::RestrictedRecord.unmark!(Hmis::Hud::Client.find(client_id)) }
    GrdaWarehouse::Hud::Client.clear_view_cache(client_id)
  end

  # The audit page names the user from the version's whodunnit, which jobs leave blank. A
  # whodunnit set by a request is kept, since it can record impersonation.
  # @param user [User]
  def self.as_actor(user, &block)
    return yield if PaperTrail.request.whodunnit.present?

    PaperTrail.request(whodunnit: user.id.to_s, &block)
  end

  # @param user [User]
  def restrict!(user:)
    # created_by is an Hmis::User (the same users row). Not as_hmis_user: it returns nil when
    # HMIS is disabled, and warehouse restrictions still need to work then.
    self.class.as_actor(user) { Hmis::RestrictedRecord.mark!(restrictable, user: Hmis::User.find(user.id)) }
    @client.clear_view_cache
  end

  # @param user [User]
  # @return [Boolean] whether a warehouse row was removed
  def unrestrict!(user:)
    removed = self.class.as_actor(user) { Hmis::RestrictedRecord.unmark!(restrictable) }.present?
    @client.clear_view_cache
    removed
  end

  # The client's PII as the user would see it with the warehouse row removed. Name permissions,
  # an HMIS restriction, and an inactive identity still hide it.
  # @param user [User]
  # @return [GrdaWarehouse::PiiProvider]
  def pii_provider_without_warehouse_restriction(user:)
    hidden = restricted_in_hmis? || GrdaWarehouse::HiddenClients.inactive_subset([@client.id]).any?
    policy = GrdaWarehouse::PiiProvider.restrict(user.policy_for(@client), restricted: hidden)
    GrdaWarehouse::PiiProvider.new(@client, policy: policy)
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
