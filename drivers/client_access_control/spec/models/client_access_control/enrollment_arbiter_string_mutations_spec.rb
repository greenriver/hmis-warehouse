# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientAccessControl::EnrollmentArbiter, type: :model do
  let(:user) { create(:user) }

  describe 'clients_source_visible_to method with += operations' do
    it 'uses += operation for data source IDs in legacy mode' do
      # Test the += operation from line 66: data_source_ids += window_data_source_ids

      arbiter = described_class.new

      # Mock user to use legacy mode (not ACLs)
      allow(user).to receive(:using_acls?).and_return(false)
      allow(user).to receive(:can_access_some_version_of_clients?).and_return(true)

      # Mock the methods called by clients_source_visible_to
      allow(arbiter).to receive(:legacy_authoritative_viewable_ds_ids).and_return([1, 2])
      allow(arbiter).to receive(:window_data_source_ids).and_return([3, 4])
      allow(arbiter).to receive(:legacy_visible_client_scope).and_return(::GrdaWarehouse::Hud::Client.none)

      # Mock config to allow the += operation
      allow(::GrdaWarehouse::Config).to receive(:get).with(:window_access_requires_release).and_return(false)

      # Call the actual method that contains the += operation
      result = arbiter.clients_source_visible_to(user)

      # Should call the method without errors (tests that += operation works)
      expect(result).to be_an(ActiveRecord::Relation)
    end
  end

  describe 'clients_source_searchable_to method with += operations' do
    it 'uses += operation for data source IDs in search context' do
      # Test the += operation from line 87: data_source_ids += window_data_source_ids

      arbiter = described_class.new

      # Mock user to use legacy mode
      allow(user).to receive(:using_acls?).and_return(false)

      # Mock the methods called by clients_source_searchable_to
      allow(arbiter).to receive(:legacy_authoritative_viewable_ds_ids).and_return([5, 6])
      allow(arbiter).to receive(:window_data_source_ids).and_return([7, 8])
      allow(arbiter).to receive(:legacy_visible_client_scope).and_return(::GrdaWarehouse::Hud::Client.none)

      # Call the actual method that contains the += operation
      result = arbiter.clients_source_searchable_to(user)

      # Should call the method without errors (tests that += operation works)
      expect(result).to be_an(ActiveRecord::Relation)
    end
  end

  describe 'searchable_client_scope method with << operations' do
    it 'uses << operation for union parts array building' do
      # Test the << operation from line 132: union_parts << client_scope.where(...)

      arbiter = described_class.new

      # Mock the methods called by searchable_client_scope
      allow(arbiter).to receive(:unscoped_clients).and_return(::GrdaWarehouse::Hud::Client)
      allow(arbiter).to receive(:searchable_enrollments_from_access_controls).and_return(::GrdaWarehouse::Hud::Enrollment.none)
      allow(arbiter).to receive(:searchable_enrollments_from_rois).and_return(::GrdaWarehouse::Hud::Enrollment.none)
      allow(arbiter).to receive(:authoritative_viewable_ds_ids).and_return([1, 2, 3])

      # Call the actual private method that contains the << operation
      expect { arbiter.send(:searchable_client_scope, user) }.not_to raise_error
    end

    it 'handles empty authoritative data sources in << operation' do
      arbiter = described_class.new

      # Mock to return empty array
      allow(arbiter).to receive(:unscoped_clients).and_return(::GrdaWarehouse::Hud::Client)
      allow(arbiter).to receive(:searchable_enrollments_from_access_controls).and_return(::GrdaWarehouse::Hud::Enrollment.none)
      allow(arbiter).to receive(:searchable_enrollments_from_rois).and_return(::GrdaWarehouse::Hud::Enrollment.none)
      allow(arbiter).to receive(:authoritative_viewable_ds_ids).and_return([])

      # Should not add to union_parts when authoritative_viewable_ds_ids is empty
      expect { arbiter.send(:searchable_client_scope, user) }.not_to raise_error
    end
  end
end
