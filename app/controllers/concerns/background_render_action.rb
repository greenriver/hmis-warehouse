#
# provides a class method for defining actions to initiate background
# background render jobs.  extend this module in a Rails controller
# 
# 
module BackgroundRenderAction
  extend ActiveSupport::Concern

  def background_render_action name, job_class, &block
    define_method name do
      job_args = {render_id: params[:render_id]}
      job_args.merge! instance_exec(&block)

      job_class.perform_later(**job_args)
      head :ok
    end
  end
end
