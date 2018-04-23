class MessagesController < ApplicationController

  def index
  end

  def show
    @message = current_user.messages.find params.require(:id)
    render layout: false
  end

  def poll
    ids = params[:ids] || []
    paths_and_subjects = messages.where.not( id: ids ).pluck( :id, :subject ).map do |id, subj|
      [ view_context.message_path(id), id, subj ]
    end
    render json: paths_and_subjects
  end

  def seen
    @notification = messages.where( id: params.require(:id) ).first
    @seen = @notification&.update_attribute :seen_at, DateTime.current
    render json: { seen: !!@seen }
  end

  private def messages
    current_user.messages.unseen.order created_at: :desc
  end

end
