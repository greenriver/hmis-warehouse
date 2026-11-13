###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Builds the object background renders hand to ActionController::Renderer as the 'warden' rack key.
# The rack env is the only channel the renderer offers for carrying a user into the controller, and
# both arms read the user back out of it — the JWT arm through Idp::JwtCurrentUser.
#
# Warden reaches the app only through the :devise bundler group, which config/application.rb
# requires only under AuthMethod.devise?, so naming Warden::Proxy outside DeviseArm raises
# NameError on the JWT arm.
module WardenProxyFactory
  module DeviseArm
    def build(user)
      Warden::Proxy.new({}, Warden::Manager.new({})).tap do |proxy|
        proxy.set_user(user, scope: :user, store: false, run_callbacks: false)
      end
    end
  end

  module JwtArm
    def build(user)
      Idp::WardenProxy.new(user)
    end
  end

  extend(AuthMethod.jwt? ? JwtArm : DeviseArm)

  # Pass this to ActionController::Renderer.new. The 'warden' key name is the contract with the
  # readers — Idp::JwtCurrentUser on the JWT arm, Devise's helpers on the Devise arm — so it is
  # spelled here rather than at each render site.
  def self.renderer_env(user)
    { 'warden' => build(user) }
  end
end
