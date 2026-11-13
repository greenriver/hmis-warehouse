###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Oauth2Proxy
  # The app's controller routes, each tagged with the authentication its before_action chain enforces.
  class RouteInventory
    USER_AUTH_FILTERS = [:authenticate_user!, :authenticate_hmis_user!].freeze
    MACHINE_AUTH_FILTERS = [:authenticate_via_jwt!, :authorize_request].freeze

    # Stands in for a controller instance when evaluating only:/except: conditions.
    ActionProbe = Struct.new(:action_name) do
      def raise_on_missing_callback_actions
        false
      end
    end

    Route = Data.define(:verb, :path_spec, :endpoint, :auth) do
      def path
        path_spec.delete_suffix('(.:format)')
      end

      def sample_paths
        dropped = path_spec
        dropped = dropped.gsub(/\([^()]*\)/, '') while dropped.include?('(')
        [dropped, path_spec.delete('()')].map { |spec| fill(spec) }.uniq
      end

      def matched_by?(patterns)
        sample_paths.any? { |sample| patterns.any? { |pattern| pattern.match?(sample) } }
      end

      def needs_proxy_skip?
        auth != :user
      end

      def to_s
        "#{verb.presence || 'ANY'} #{path} (#{endpoint})"
      end

      private def fill(spec)
        spec.gsub(/:format\b/, 'json').gsub(/:\w+/, '1').gsub(/\*\w+/, 'a/b')
      end
    end

    def self.auth_for(controller_class, action)
      probe = ActionProbe.new(action.to_s)
      filters = controller_class._process_action_callbacks.
        select { |callback| callback.kind == :before && runs?(callback, probe) }.
        map(&:filter)
      return :user if filters.intersect?(USER_AUTH_FILTERS)
      return :machine if filters.intersect?(MACHINE_AUTH_FILTERS)

      :none
    end

    # A proc or method condition can switch the callback off at request time, so a callback with one
    # counts as not running.
    def self.runs?(callback, probe)
      # ActiveSupport::Callbacks::Callback has no public reader for its conditions.
      ifs = callback.instance_variable_get(:@if)
      unlesses = callback.instance_variable_get(:@unless)
      return false unless (ifs + unlesses).all?(AbstractController::Callbacks::ActionFilter)

      ifs.all? { |condition| condition.match?(probe) } && unlesses.none? { |condition| condition.match?(probe) }
    end
    private_class_method :runs?

    def initialize(route_set = Rails.application.routes)
      @route_set = route_set
    end

    # A route whose controller doesn't load answers with a routing error, so it needs no proxy skip.
    def routes
      @routes ||= @route_set.routes.filter_map do |route|
        controller = route.defaults[:controller]
        controller_class = "#{controller.camelize}Controller".safe_constantize if controller
        next unless controller_class

        action = route.defaults[:action]
        Route.new(
          verb: route.verb,
          path_spec: route.path.spec.to_s,
          endpoint: "#{controller}##{action}",
          auth: self.class.auth_for(controller_class, action),
        )
      end
    end
  end
end
