###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'

  context 'when config b is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      AccessGroup.maintain_system_groups
    end
    let!(:config) { create :config_b }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end

      describe 'and the user has all data source group' do
        before do
          AccessGroup.where(name: 'All Data Sources').first.users << user
        end
        it 'user can see all clients' do
          expect(GrdaWarehouse::Hud::Client.source.source_visible_to(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.destination.destination_visible_to(user).count).to eq(2)
        end
      end
    end

    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      describe 'and the user is assigned a data source' do
        before do
          user.roles << can_view_clients
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(2)
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
          end
        end
      end
    end
  end

  context 'when config s is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_s }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        AccessGroup.where(name: 'All Data Sources').first.users << user
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(2)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).pluck(:id)).to include(window_source_client.id)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
      end
      it 'user can see client dashboard for window client with release' do
        past_date = 5.days.ago
        future_date = Date.current + 1.years
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: past_date,
          consent_expires_on: future_date,
        )
        expect(window_destination_client.show_demographics_to?(user)).to eq true
      end
      it 'user cannot see client dashboard for non-window client' do
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(1)
        client = GrdaWarehouse::Hud::Client.searchable_by(user).first
        expect(client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source but not details of window clients' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
          end
        end
      end
    end
  end

  context 'when config 3c is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_3c }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        AccessGroup.where(name: 'All Data Sources').first.users << user
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(2)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        client = GrdaWarehouse::Hud::Client.source_visible_to(user).first
        expect(client.show_demographics_to?(user)).to eq false
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
            expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
          end
        end
      end
    end
  end

  context 'when config tc is in affect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_tc }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        AccessGroup.where(name: 'All Data Sources').first.users << user
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(2)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
      end
      it 'user can search only window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        client = GrdaWarehouse::Hud::Client.source_visible_to(user).first
        expect(client.show_demographics_to?(user)).to eq false
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
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
    end
    let!(:config) { create :config_ma }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        AccessGroup.where(name: 'All Data Sources').first.users << user
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(2)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      it 'user can see client dashboard for window client with release' do
        past_date = 5.days.ago
        future_date = Date.current + 1.years
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: past_date,
          consent_expires_on: future_date,
        )
        expect(window_destination_client.show_demographics_to?(user)).to eq true
      end
      it 'user cannot see client dashboard for non-window client' do
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
      end
    end
    describe 'and the user has a role granting can use strict search' do
      before do
        user.roles << can_use_strict_search
      end
      it 'user can only search, not see, window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
      end
      it 'can search for but not see window clients' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        client = GrdaWarehouse::Hud::Client.searchable_by(user).first
        expect(client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source but not details of window clients' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        end
      end
    end
    describe 'and the user has a role granting visibility by coc release' do
      before do
        user.roles << can_view_clients
      end
      it 'user can search for all clients, but not see details' do
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.searchable_by(user).pluck(:id)).to include(non_window_source_client.id)
        expect(window_destination_client.show_demographics_to?(user)).to eq false
        expect(non_window_destination_client.show_demographics_to?(user)).to eq false
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
      describe 'and the user is assigned a CoC' do
        before do
          user.coc_codes = ['ZZ-999']
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
          end
          it 'user can see client dashboard for assigned client' do
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
    end
    let!(:config) { create :config_va }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        AccessGroup.where(name: 'All Data Sources').first.users << user
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(2)
      end
    end
    describe 'and the user has a role granting can search own clients' do
      before do
        user.roles << can_search_own_clients
        user.roles << can_view_clients
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
          user.add_viewable(non_window_project)
        end
        it 'search only returns clients based on data assignment' do
          expect(GrdaWarehouse::Hud::Client.searchable_by(user).count).to eq(1)
          expect(window_destination_client.show_demographics_to?(user)).to eq false
          expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        end
      end
    end
    describe 'and the user has a role granting visibility by coc release but no assignments' do
      before do
        user.roles << can_search_own_clients
        user.roles << can_view_clients
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
          user.coc_codes = ['ZZ-999']
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
          end
          it 'user still cannot see client dashboard for any client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq false
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
        describe 'when the client does not have a valid consent but the user has a CoC Code matching the enrollment' do
          before do
            user.coc_codes = ['ZZ-000']
            non_window_destination_client.update(
              housing_release_status: nil,
              consent_form_signed_on: nil,
              consent_expires_on: nil,
              consented_coc_codes: [],
            )
          end
          it 'user can see client dashboard for assigned client' do
            expect(non_window_destination_client.show_demographics_to?(user)).to eq true
          end
          it 'user still cannot see client dashboard for unassigned client' do
            expect(window_destination_client.show_demographics_to?(user)).to eq false
          end
        end
      end
    end
  end

  context 'enrollments included in verified homeless history' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
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
      let!(:user) { create :user }
      before do
        config.update(verified_homeless_history_method: :visible_to_user)
        user.roles << can_view_clients
      end
      it 'enrollments visible to user are included' do
        # confirm client has 1 enrollment, but it's not included because it's not visible
        expect(non_window_source_client.service_history_enrollments.count).to eq 1
        expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

        # add visibility and confirm it's included
        user.add_viewable(non_window_project)
        expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
      end
    end

    describe 'when release config selected' do
      let!(:user) { create :user }
      before do
        config.update(verified_homeless_history_method: :release)
      end
      describe 'and client has valid release in users CoC' do
        before do
          user.coc_codes = ['ZZ-999']
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

      describe 'and client has valid release in any CoC' do
        before do
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

      describe 'and client has valid release in a different CoC' do
        before do
          user.roles << can_view_clients
          user.coc_codes = ['ZZ-100']
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
          user.add_viewable(non_window_project)
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end

      describe 'and client does not have a valid release' do
        before do
          user.roles << can_view_clients
        end
        it 'enrollments visible to user included' do
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 0

          # add visibility and confirm it gets included
          user.add_viewable(non_window_project)
          expect(non_window_source_client.enrollments_for_verified_homeless_history(user: user).count).to eq 1
        end
      end
    end
  end
end
