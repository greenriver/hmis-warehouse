###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#
# provides a class method for defining actions to initiate background
# background render jobs.  extend this module in a Rails controller
#
#
module BackgroundRenderAction
  extend ActiveSupport::Concern

  def background_render_action name, job_class, &block
    define_method name do
      job_args = {}
      job_args.merge! instance_exec(&block)

      job_class.perform_later(params[:render_id], **job_args)
      head :ok
    end
  end
end
