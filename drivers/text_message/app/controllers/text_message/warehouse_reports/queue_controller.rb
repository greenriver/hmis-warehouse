###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage::WarehouseReports
  class QueueController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include BaseFilters

    def index
      tm_m_t = TextMessage::Message.arel_table
      @text_messages = TextMessage::Message.joins(topic_subscriber: :topic).
        preload(topic_subscriber: :topic).
        where(
          tm_m_t[:send_on_or_after].between(@filter.range).
          or(tm_m_t[:sent_at].between(@filter.start.to_time..@filter.end.to_time.end_of_day)),
        ).
        order(:send_on_or_after).
        page(params[:page]).per(100)
    end

    def filter_params
      options = params.permit(
        filters: [
          :start,
          :end,
        ],
      )
      if options.blank?
        options = {
          filters: {
            start: Date.current,
            end: Date.current + 1.weeks,
          },
        }
      end
      options
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
