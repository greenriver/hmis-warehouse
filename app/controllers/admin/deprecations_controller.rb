# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# tests for proper deprecation handling
TodoOrDie('Remove after next rails version', if: Rails.version !~ /\A7\.1/)
module Admin
  class DeprecationsController < ApplicationController
    before_action :require_can_manage_config!

    def show
      # this is for internal testing after we deploy the rails upgrade
      raise unless current_user.email =~ /greenriver.org\z/

      case params[:test]
      when 'test_deprecated_tx_break'
        result = test_deprecated_tx(rollback: :break)
        render json: { result: result }
      when 'test_deprecated_tx_return'
        result = test_deprecated_tx(rollback: :return)
        render json: { result: result }
      else
        head :not_found
      end
    end

    protected

    def test_deprecated_tx(rollback:)
      user = User.find(current_user.id)
      previous_value = user.deprecated_uid
      run_deprecated_tx(rollback:, user:)
      user.reload
      [user.deprecated_uid, previous_value]
    end

    def run_deprecated_tx(rollback:, user:)
      user.transaction do
        # hijack the old uid to test the deprecation
        user.deprecated_uid = SecureRandom.uuid
        user.save!

        # Legacy behavior rolls back, new (>=7.1) is to commit
        break if rollback == :break
        return if rollback == :return

        raise 'should not reach here'
      end
    end
  end
end
