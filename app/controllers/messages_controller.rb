class MessagesController < ApplicationController
  include PjaxModalController

  def index
    @hide_messages = true
    if id = message_params[:id].presence
      @message = messages.find id
      @message.update_attribute :seen_at, DateTime.current unless @message.opened?
    end
    @search = message_params[:search].presence || 'unseen'
    @messages = case @search
    when 'all'
      messages
    when 'unseen'
      @description = 'unread'
      messages.unseen
    end
    @messages = @messages.page(message_params[:page]).per(25)
  end

  private def message_params
    @message_params ||= params.permit :search, :id, :page
  end
  helper_method :message_params

  def show
    @message = current_user.messages.find params.require(:id)
  end

  def poll
    ids = params[:ids] || []
    @messages = messages.unseen.where.not( id: ids ).limit(10)
    paths_and_subjects = @messages.pluck( :id, :subject ).reverse.map do |id, subj|
      [ view_context.message_path(id), id, subj ]
    end
    render json: paths_and_subjects
  end

  def seen
    @notification = messages.unseen.find params.require(:id)
    @notification&.update_attribute :seen_at, DateTime.current unless @notification.opened?
    head :ok
  end

  private def messages
    current_user.messages.order( created_at: :desc )
  end

end
