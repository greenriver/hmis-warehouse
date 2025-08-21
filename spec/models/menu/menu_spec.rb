###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Menu::Menu, type: :model do
  let(:context) { double('context') }
  let!(:analytics_report) { create(:op_analytics_report) }
  let(:menu) { described_class.new(user: user, context: context) }

  before do
    allow(RailsDrivers).to receive(:loaded).and_return([:superset])
    allow(Superset).to receive(:available?).and_return(true)
  end

  subject { menu.op_analytics_menu }

  describe '#op_analytics_menu' do
    let(:visibility_check) { subject.visible }

    context 'with an ACL user' do
      let(:user) { create(:acl_user) }

      context 'when user has can_view_all_reports permission' do
        let(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }
        let!(:collection) { create(:collection) }

        context 'and is not assigned the superset report' do
          before do
            setup_access_control(user, role, collection)
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            collection.set_viewables({ reports: [analytics_report.id] })
            setup_access_control(user, role, collection)
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end

      context 'when user has can_view_assigned_reports permission' do
        let(:role) { create(:role, can_view_assigned_reports: true) }
        let!(:collection) { create(:collection) }

        context 'and is not assigned the superset report' do
          before do
            setup_access_control(user, role, collection)
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            collection.set_viewables({ reports: [analytics_report.id] })
            setup_access_control(user, role, collection)
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }
      let!(:access_group) { create(:access_group) }

      context 'when user has can_view_all_reports permission' do
        let(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }

        context 'and is not assigned the superset report' do
          before do
            user.legacy_roles = [role]
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            user.legacy_roles = [role]
            access_group.reports << analytics_report
            user.access_groups << access_group
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end

      context 'when user has can_view_assigned_reports permission' do
        let(:role) { create(:role, can_view_assigned_reports: true) }

        context 'and is not assigned the superset report' do
          before do
            user.legacy_roles = [role]
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            user.legacy_roles = [role]
            access_group.reports << analytics_report
            user.access_groups << access_group
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end
    end
  end
end
