###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Users::InvitationsController is ignored by the autoloader under JWT (config/application.rb), so its
# routes must be mounted only on the Devise arm
RSpec.describe 'users/invitations routing', type: :routing do
  describe 'under Devise', :devise_only do
    it 'routes GET /users/invitation/new to users/invitations#new' do
      expect(get: '/users/invitation/new').to route_to(
        controller: 'users/invitations',
        action: 'new',
      )
    end

    it 'routes POST /users/invitations/confirm to users/invitations#confirm' do
      expect(post: '/users/invitations/confirm').to route_to(
        controller: 'users/invitations',
        action: 'confirm',
      )
    end
  end

  # Not `be_routable`: recognize_path raises RoutingError for a route to an unloaded controller too, so
  # it can't tell an unmounted route from the bug this guards against
  describe 'under JWT', :jwt_only do
    it 'mounts no route to users/invitations' do
      invitation_route_paths = Rails.application.routes.routes.
        select { |route| route.defaults[:controller] == 'users/invitations' }.
        map { |route| route.path.spec.to_s }

      expect(invitation_route_paths).to be_empty
    end
  end
end
