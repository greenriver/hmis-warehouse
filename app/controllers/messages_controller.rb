class MessagesController < ApplicationController

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
    @messages = @messages.order( created_at: :desc ).page(message_params[:page]).per(25)
  end

  private def message_params
    @message_params ||= params.permit :search, :id, :page
  end
  helper_method :message_params

  def show
    @message = current_user.messages.find params.require(:id)
    render layout: false
  end

  def poll
    ids = params[:ids] || []
    @messages = messages.unseen.order( created_at: :asc ).where.not( id: ids )
    paths_and_subjects = @messages.pluck( :id, :subject ).map do |id, subj|
      [ view_context.message_path(id), id, ApplicationMailer.remove_prefix(subj) ]
    end
    render json: paths_and_subjects
  end

  def seen
    @notification = messages.unseen.find params.require(:id)
    @seen = @notification&.update_attribute :seen_at, DateTime.current
    render json: { seen: !!@seen }
  end

  private def messages
    current_user.messages
  end

end
