###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'

  context 'when config b is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_b }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end

      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end

      describe 'and the user has all data source group' do
        before do
          setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
        end
        it 'user can see all clients' do
          expect(GrdaWarehouse::Hud::Client.source.source_visible_to(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.destination.destination_visible_to(user).count).to eq(3)
          expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
        end
      end
    end

    describe 'and the user has a role granting can search window' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      describe 'and the user is assigned a data source' do
        before do
          setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
          setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            setup_access_control(user, can_search_own_clients, non_window_data_source_viewable_collection)
            setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(4)
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
          end
        end
      end
    end
  end

  context 'when config s is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_s }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(3)
        expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        # NOTE the difference here, this installation requires an ROI to see client data in the window
        setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).pluck(:id)).to include(window_source_client.id)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
      end
      it 'exposes the window source client, its enrollment, and its dashboard after a release' do
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).pluck(:id)).to be_empty
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: 5.days.ago,
          consent_expires_on: Date.current + 1.years,
        )
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([window_destination_client.id])

        expect(window_destination_client.show_demographics_to?(user)).to eq true
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to contain_exactly(window_source_client.id)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).pluck(:id)).to contain_exactly(window_enrollment.id)
      end
      it 'user cannot see client dashboard for non-window client' do
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
      end
      it 'answers the dashboard gate from the preloaded policy context without querying' do
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: 5.days.ago,
          consent_expires_on: Date.current + 1.years,
        )
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([window_destination_client.id])
        viewer = User.find(user.id)
        viewer.policy_context.preload_client_dependencies([window_destination_client.id, non_window_destination_client.id])

        # The user's role load and the user_clients relationship check also run here; only the
        # ROI gate's own tables are counted
        roi_queries = 0
        counter = ->(*, payload) { roi_queries += 1 if payload[:sql].match?(/"(client_roi_authorizations|warehouse_clients|data_sources)"/) }
        answers = nil
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
          answers = [window_destination_client, non_window_destination_client].map { |c| c.show_demographics_to?(viewer) }
        end

        expect(answers).to eq([true, false])
        expect(roi_queries).to eq(0)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        client = GrdaWarehouse::Hud::Client.searchable_by(user).first
        expect(client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          setup_access_control(user, can_search_own_clients, non_window_data_source_viewable_collection)
          setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
        end
        it 'user can see one client in expected data source but not details of window clients' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        end
        describe 'and the user can search the window' do
          before do
            # setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
          end
        end
      end
    end
  end

  context 'when config 3c is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_3c }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(3)
        expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        client = GrdaWarehouse::Hud::Client.source_visible_to(user).first
        expect(client.show_demographics_to?(user)).to eq false
      end
      describe 'and the user is assigned a data source' do
        before do
          setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_search_own_clients, non_window_data_source_viewable_collection)
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
            expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
          end
        end
      end
    end
  end

  context 'when config tc is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_tc }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(3)
        expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can search only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end

    describe 'and the user has a role granting visibility by data source' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        client = GrdaWarehouse::Hud::Client.source_visible_to(user).first
        expect(client.show_demographics_to?(user)).to eq false
      end
      describe 'and the user is assigned a data source' do
        before do
          setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_search_own_clients, non_window_data_source_viewable_collection)
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
          end
        end
      end
    end
  end

  context 'when config ma is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      # Note, all data sources are visible in the window for ma
      non_window_visible_data_source.update(visible_in_window: true)
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_ma }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(3)
        expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      it 'exposes the window source client, its enrollment, and its dashboard after a release' do
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).pluck(:id)).to be_empty
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: 5.days.ago,
          consent_expires_on: Date.current + 1.years,
        )
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([window_destination_client.id])

        expect(window_destination_client.show_demographics_to?(user)).to eq true
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to contain_exactly(window_source_client.id)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).pluck(:id)).to contain_exactly(window_enrollment.id)
      end
      it 'user cannot see client dashboard for non-window client' do
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
      end
    end
    describe 'and the user has a role granting can use strict search (note strict search only affects controller/view logic)' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
        client = GrdaWarehouse::Hud::Client.searchable_by(user).first
        expect(client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
          setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
        end
        it 'user can see one client in expected data source but not details of window clients' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        end
      end
    end
    describe 'and the user has a role granting visibility by coc release' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      end
      it 'user can search for all clients, but not see details' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a CoC' do
        before do
          coc_code_viewable_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: 'ZZ-999').pluck(:id) })
          setup_access_control(user, no_permission_role, coc_code_viewable_collection)
        end
        it 'user cannot see client details' do
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq false
        end
        describe 'when the client has a valid consent in any coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: [],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user can see client dashboard for released client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end
          it 'user cannot see client dashboard for window client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in the user\'s coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user can see client dashboard for assigned client' do
            expect(user.coc_codes).to include('ZZ-999')
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end
          it 'user cannot see client dashboard for window client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in the user\'s coc and another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user can see client dashboard for assigned client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end
          it 'user cannot see client dashboard for window client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['AA-000'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user cannot see client dashboard for assigned client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
          end
          it 'user cannot see client dashboard for window client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
      end
    end
  end

  context 'when config va is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      # mimic implicit consent since we aren't using Identify Duplicates
      GrdaWarehouse::Hud::Client.destination.update_all(
        housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
      )
      # VA has no window visible data sources
      window_visible_data_source.update(visible_in_window: false)
      Collection.maintain_system_groups
    end
    let!(:config) { create :config_va }
    let!(:user) { create :acl_user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(4)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(3)
        expect(GrdaWarehouse::Hud::Client.destination_or_source_visible_to(user).count).to eq(7)
      end
    end
    describe 'and the user has a role granting can search own clients' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      describe 'but the user has no assignments' do
        it 'search returns no clients' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(0)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        end
      end
      describe 'and the user has one assignment' do
        before do
          setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
          setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
          setup_access_control(user, can_search_own_clients, non_window_project_viewable_collection)
          setup_access_control(user, can_view_clients, non_window_project_viewable_collection)
        end
        it 'search only returns clients based on data assignment' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        end
      end
    end
    describe 'and the user has a role granting visibility by coc release but no assignments' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'user can only search for their own clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to_not include(non_window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a CoC' do
        before do
          coc_code_viewable_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: 'ZZ-999').pluck(:id) })
          setup_access_control(user, no_permission_role, coc_code_viewable_collection)
        end
        it 'user cannot see client details for someone not in their projects' do
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq false
        end
        describe 'when the client has a valid consent in any coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: [],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in the user\'s coc but the enrollment occurred elsewhere' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in the user\'s coc and another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client has a valid consent in another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['AA-000'],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client does not have a valid consent' do
          before do
            non_window_destination_client.update(
              housing_release_status: nil,
              consent_form_signed_on: nil,
              consent_expires_on: nil,
              consented_coc_codes: [],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client does not have a valid consent and the user has a CoC Code matching the enrollment' do
          before do
            coc_code_viewable_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: 'ZZ-000').pluck(:id) })
            setup_access_control(user, can_view_clients, coc_code_viewable_collection)
            non_window_destination_client.update(
              housing_release_status: nil,
              consent_form_signed_on: nil,
              consent_expires_on: nil,
              consented_coc_codes: [],
            )
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
            # FIXME
            # non_window_destination_client.source_enrollments.first.update(enrollment_coc: 'ZZ-000')
          end
          it 'user can see client dashboard for assigned client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end
          it 'user still cannot see client dashboard for unassigned client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'and the user also holds the ROI view permission' do
          before do
            # The outer before creates a default config row before the config_va let! runs, and Config.get
            # reads the first row, so replace both to get Consent::Implied
            GrdaWarehouse::Config.delete_all
            create :config_va
            GrdaWarehouse::Config.invalidate_cache
            setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:data_sources))
          end

          def release!(status)
            non_window_destination_client.update_columns(housing_release_status: status, consented_coc_codes: [])
            GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([non_window_destination_client.id])
          end

          it 'shows the dashboard for a client with expanded consent' do
            release!(Consent::Implied.full_release_string)
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end

          it 'hides the dashboard for a client with only implied consent' do
            release!(Consent::Implied.no_release_string)
            expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: non_window_destination_client.id).status).to eq('partial')
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
      end
    end
  end

  context 'enrollments included in verified homeless history' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      Collection.maintain_system_groups
    end
    let!(:config) { create :config }
    describe 'when all_enrollments config selected' do
      before do
        config.update(verified_homeless_history_method: :all_enrollments)
      end
      it 'all enrollments included' do
        scope = window_source_client.enrollments_for_verified_homeless_history
        expect(scope.count).to eq 1

        scope = non_window_source_client.enrollments_for_verified_homeless_history
        expect(scope.count).to eq 1
      end
    end
    describe 'when visible_in_window config selected' do
      before do
        config.update(verified_homeless_history_method: :visible_in_window)
      end
      it 'enrollments visible in the window are included' do
        scope = window_source_client.enrollments_for_verified_homeless_history
        expect(scope.count).to eq 1

        scope = non_window_source_client.enrollments_for_verified_homeless_history
        expect(scope.count).to eq 0
      end
    end
    describe 'when visible_to_user config selected' do
      let!(:user) { create :acl_user }
      before do
        config.update(verified_homeless_history_method: :visible_to_user)
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      end
      it 'enrollments visible to user are included' do
        # confirm client has 1 enrollment, but it's not included because it's not visible
        expect(non_window_source_client.service_history_enrollments.count).to eq 1
        expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

        # add visibility and confirm it's included
        setup_access_control(user, can_view_clients, non_window_project_viewable_collection)
        expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
      end
    end

    describe 'when release config selected' do
      let!(:user) { create :acl_user }
      before do
        config.update(verified_homeless_history_method: :release)
      end
      describe 'and client has valid release in users CoC' do
        before do
          coc_code_viewable_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: 'ZZ-999').pluck(:id) })
          setup_access_control(user, no_permission_role, coc_code_viewable_collection)
          non_window_source_client.update(
            housing_release_status: non_window_source_client.class.full_release_string,
            consent_form_signed_on: 5.days.ago,
            consent_expires_on: Date.current + 1.years,
            consented_coc_codes: ['ZZ-999'],
          )
        end
        it 'all enrollments included' do
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end

      describe 'and client has valid release, but user does not have assigned coc_codes' do
        before do
          coc_code_viewable_collection.set_viewables({ coc_codes: [] })
          setup_access_control(user, no_permission_role, coc_code_viewable_collection)
          setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
          non_window_source_client.update(
            housing_release_status: non_window_source_client.class.full_release_string,
            consent_form_signed_on: 5.days.ago,
            consent_expires_on: Date.current + 1.years,
            consented_coc_codes: ['ZZ-999'],
          )
        end
        it 'enrollments visible to user included' do
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

          # add visibility and confirm it gets included
          setup_access_control(user, can_view_clients, non_window_project_viewable_collection)

          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end

      describe 'and client has valid release in a different CoC' do
        before do
          setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
          coc_code_viewable_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: 'ZZ-100').pluck(:id) })
          setup_access_control(user, no_permission_role, coc_code_viewable_collection)
          non_window_source_client.update(
            housing_release_status: non_window_source_client.class.full_release_string,
            consent_form_signed_on: 5.days.ago,
            consent_expires_on: Date.current + 1.years,
            consented_coc_codes: ['ZZ-999'],
          )
        end
        it 'enrollments visible to user included' do
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

          # add visibility and confirm it gets included
          setup_access_control(user, can_view_clients, non_window_project_viewable_collection)

          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end

      describe 'and client does not have a valid release' do
        before do
          setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
        end
        it 'enrollments visible to user included' do
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

          # add visibility and confirm it gets included
          setup_access_control(user, can_view_clients, non_window_project_viewable_collection)

          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end
    end
  end
end
