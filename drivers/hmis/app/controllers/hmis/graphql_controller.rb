###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class GraphqlController < Hmis::BaseController
    # If accessing from outside this domain, nullify the session
    # This allows for outside API access while preventing CSRF attacks,
    # but you'll have to authenticate your user separately
    before_action :attach_data_source_id

    def execute
      context = {
        current_user: current_hmis_user,
      }
      case params[:schema]
      when :hmis
        if params[:_json]
          # We have a batch of operations
          queries = params[:_json].map do |param|
            {
              query: param[:query],
              operation_name: param[:operationName],
              variables: prepare_variables(param[:variables]),
              context: context,
            }
          end
          result = HmisSchema.multiplex(queries)&.to_json
        else
          # We have a single operation
          result = HmisSchema.execute(
            query: params[:query],
            variables: prepare_variables(params[:variables]),
            context: context,
            operation_name: params[:operationName],
          )
        end
      end
      render json: result
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end

    private

    # Handle variables in form data, JSON body, or a blank value
    def prepare_variables(variables_param)
      case variables_param
      when String
        if variables_param.present?
          JSON.parse(variables_param) || {}
        else
          {}
        end
      when Hash
        variables_param
      when ActionController::Parameters
        variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: #{variables_param}"
      end
    end

    def handle_error_in_development(err)
      logger.error err.message
      logger.error err.backtrace.join("\n")

      render json: { errors: [{ message: err.message, backtrace: err.backtrace }], data: {} }, status: 500
    end
  end
end
