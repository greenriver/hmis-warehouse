require 'test_helper'

class ClientTest < ActiveSupport::TestCase

  def test_any_destination_clients
    assert clients.destination.exists?, 'there are some destination clients'
  end

  def test_any_source_clients
    assert clients.source.exists?, 'there are some source clients'
  end

  def test_merge_candidates
    client = clients.destination.first
    assert client.present? && client.merge_candidates.any?, 'can find merge candidates'
  end

  def clients
    GrdaWarehouse::Hud::Client
  end
end
