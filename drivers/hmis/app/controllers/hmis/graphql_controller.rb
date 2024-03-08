###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      # not sure if this is needed, do we plan to support other schemas?
      raise unless params[:schema] == :hmis

      # Additional tags for grouping errors in Sentry
      Sentry.set_tags({ 'hmis.route': request.headers['X-Hmis-Path'].presence&.gsub(/\/([0-9]+)(\/|$)/, '/:id/') })

      begin
        result = params[:_json] ? query_multiplex : query_single
        render json: result
      rescue StandardError => e
        handle_graphql_exception(e)
      end
    end

    protected

    def query_multiplex
      queries = []
      log_records = []
      params[:_json].each do |gql_param|
        queries << query_for_params(gql_param)
        log_records << graphql_activity_log(gql_param)
      end
      result = HmisSchema.multiplex(queries)
      log_records.zip(queries).each do |log_record, query|
        logger = query.dig(:context, :activity_logger)
        log_record.merge!(logger.activity_log_attrs)
      end
      Hmis::ActivityLog.insert_all!(log_records)
      result
    end

    def query_single
      log_record = graphql_activity_log(params)
      query = query_for_params(params)
      result = HmisSchema.execute(**query)
      logger = query.dig(:context, :activity_logger)
      log_record.merge!(logger.activity_log_attrs)
      Hmis::ActivityLog.insert_all!([log_record])
      result
    end

    def query_for_params(gql_param)
      {
        query: gql_param.fetch(:query),
        operation_name: gql_param[:operationName],
        variables: prepare_variables(gql_param[:variables]),
        context: {
          current_user: current_hmis_user,
          true_user: true_hmis_user,
          activity_logger: Hmis::GraphqlFieldLogger.new,
        },
      }
    end

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

    # Return exception as an Apollo-formatted error response
    # Exposes a 500 to the client. Note for future refactor: there is an rescue mechanism built into
    # ruby-graphql: https://graphql-ruby.org/errors/error_handling.html
    def handle_graphql_exception(err)
      Rails.logger.error err.message
      Rails.logger.error err.backtrace.join("\n")

      Sentry.capture_exception_with_info(
        err,
        err.message,
        { backtrace: err.backtrace.to_s },
      )

      dev_or_test = Rails.env.test? || Rails.env.development?

      display_message = if dev_or_test
        err.message
      elsif err.is_a?(HmisErrors::ApiError)
        err.display_message
      elsif err.is_a?(ActiveRecord::StaleObjectError)
        HmisErrors::ApiError::STALE_OBJECT_ERROR
      else
        HmisErrors::ApiError::INTERNAL_ERROR_DISPLAY_MESSAGE
      end

      render status: 500, json: {
        errors: [
          {
            message: display_message,
            backtrace: dev_or_test ? err.backtrace : nil,
          },
        ],
        data: {},
      }
    end

    def graphql_activity_log(gql_param)
      {
        user_id: true_hmis_user.id,
        data_source_id: current_hmis_user.hmis_data_source_id,
        ip_address: request.remote_ip&.to_s,
        session_hash: session.id&.to_s,
        variables: gql_param[:variables],
        # these are pulled from headers so they are not necessarily safe, could be tampered with
        referer: request.referer,
        operation_name: gql_param[:operationName],
        header_page_path: request.headers['X-Hmis-Path'].presence,
        header_client_id: request.headers['X-Hmis-Client-Id'].presence&.to_i,
        header_enrollment_id: request.headers['X-Hmis-Enrollment-Id'].presence&.to_i,
        header_project_id: request.headers['X-Hmis-Project-Id'].presence&.to_i,
        created_at: DateTime.current,
      }
    end
  end
end
