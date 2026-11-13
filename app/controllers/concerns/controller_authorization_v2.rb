###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-permissions.md
module ControllerAuthorizationV2
  extend ActiveSupport::Concern

  # The only:/except: condition for authorize_with, modeled on Rails' ActionFilter. It always
  # raises when a listed action doesn't exist: a misspelled name in an authorization rule
  # would otherwise leave the action checked by the wrong rule, or by none.
  #
  # TODO: once config.action_controller.raise_on_missing_callback_actions is enabled, delete this
  # class and pass only:/except: straight to before_action.
  class ActionFilter
    def initialize(conditional_key, actions)
      @conditional_key = conditional_key
      @actions = Array(actions).map(&:to_s).to_set
    end

    def match?(controller)
      missing_action = @actions.find { |action| !controller.available_action?(action) }
      if missing_action
        raise ArgumentError, "The #{missing_action} action could not be found for the authorize_with callback " \
          "on #{controller.class.name}, but it is listed in its #{@conditional_key.inspect} option."
      end

      @actions.include?(controller.action_name)
    end
  end

  class_methods do
    def authorize_with(only: nil, except: nil, &block)
      # only: becomes if:, except: becomes unless:, as Rails does for callbacks
      conditions = {}
      if only
        only_filter = ActionFilter.new(:only, only)
        conditions[:if] = ->(controller) { only_filter.match?(controller) }
      end
      if except
        except_filter = ActionFilter.new(:except, except)
        conditions[:unless] = ->(controller) { except_filter.match?(controller) }
      end

      before_action(**conditions) do |controller|
        result = instance_exec(&block)
        case result
        when true
          controller.send(:authorization_performed!)
        when false
          controller.send(:not_authorized!)
        else
          raise TypeError, "authorize_with block must return true or false, got #{result.class}"
        end
      end
    end
  end

  private

  # Runs after the whole before_action chain, including callbacks subclasses add, and before the
  # action body, so an action missed by authorize_with will raise before it can do anything.
  def send_action(...)
    raise AuthorizationNotPerformedError unless authorization_performed?

    super
  end

  def authorization_performed!
    @_controller_authorization_v2_performed = true
  end

  def authorization_performed?
    @_controller_authorization_v2_performed == true
  end
end
