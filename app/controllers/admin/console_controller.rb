# frozen_string_literal: true

if Rails.env.staging? || Rails.env.development?
  require 'irb'
  require 'irb/completion'

  class Admin::ConsoleController < ApplicationController
    before_action :require_can_manage_config!
    before_action :verify_token!

    # extra layer of paranoia. We're already authenticated as admin
    # FIXME- take this out if we are considering merging
    protected def verify_token!
      return if Rails.env.development?

      token = params[:token]
      public_token_sha1 = 'efcc4b1ee12060e65cfef0b5b8f52fa7ed7b343e'
      raise unless token && Digest::SHA1.hexdigest(token) == public_token_sha1
      raise unless Date.current.to_fs(:db).in?(['2025-03-19', '2025-03-20'])
    end

    def index
      # Just render the view
    end

    def execute
      code = params[:code].to_s.strip
      return head :no_content if code.blank?

      begin
        # Capture stdout to get printed output
        stdout_capture = StringIO.new
        original_stdout = $stdout
        $stdout = stdout_capture

        # Execute the code in the context of the Rails app
        result = eval(code, binding)

        # Get any stdout output
        $stdout = original_stdout
        output = stdout_capture.string

        # Combine output with the return value
        response_text = if output.present?
          "#{output}\n=> #{result.inspect}"
        else
          "=> #{result.inspect}"
        end

        render json: { output: response_text, command: code }
      rescue StandardError => e
        render json: {
          output: "Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}",
          command: code,
          error: true,
        }
      end
    end
  end
end
