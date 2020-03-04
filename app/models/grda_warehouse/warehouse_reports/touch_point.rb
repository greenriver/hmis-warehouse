###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class TouchPoint < Base
    include Rails.application.routes.url_helpers
    require 'csv'

    belongs_to :user

    def title
      'Touch Point Export'
    end

    def url
      warehouse_reports_touch_point_exports_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
      update(started_at: Time.current)
      update(
        data: clean_data(computed_data),
        finished_at: Time.current,
      )
    end

    # Convert the complex data structure to an array of arrays
    # for easier storage and Excel export
    def clean_data(dirty)
      @cleaned_data ||= begin
        clean = []
        section_columns = sections(dirty).map do |title, questions|
          column_count = questions.size - 1
          column_count = 0 if column_count < 0
          [title] + [nil]*(column_count)
        end
        clean << ['Selected Range:', start_date, end_date] + section_columns.flatten
        clean << ["Client ID", "Client Name", "Collected On", "Location", "Staff"] + all_questions(dirty)
        responses.find_each do |response|
          row = []
          client_id = response.client.destination_client.id
          client_name = response.client.destination_client.name
          row << client_id
          row << client_name
          row << response.collected_at
          row << response.hmis_assessment.site_name
          row << response.staff
          sections(dirty).each do |title, questions|
            questions.each do |question|
              row << dirty.dig(:sections, title, question, client_id, response.id)
            end
          end
          clean << row
        end
        clean
      end
    end

    def sections(dirty)
      @sections ||= dirty[:sections].map{|section_title, questions| [section_title, questions.keys]}.to_h
    end

    def all_questions(dirty)
      @all_questions ||= sections(dirty).values.flatten
    end
    # def compute_data
    #   section_columns = @sections.map do |section, questions|
    #     column_count = questions.size - 1
    #     column_count = 0 if column_count < 0
    #     [section] + [nil]*(column_count)
    #   end
    #   sheet.add_row ['Selected Range:', @start_date, @end_date] + section_columns.flatten
    #   sheet.add_row ["Client ID", "Client Name", "Collected On", "Location", "Staff"] + @sections.values.flatten

    #   @responses.each do |response|
    #     row = []
    #     client_id = response.client.destination_client.id
    #     client_name = response.client.destination_client.name
    #     row << client_id
    #     row << client_name
    #     row << response.collected_at
    #     row << response.hmis_assessment.site_name
    #     row << response.staff
    #     @sections.each do |title, questions|
    #       questions.each do |question|
    #         row << @data.dig(:sections, title, question, client_id, response.id)
    #       end
    #     end
    #     sheet.add_row row
    #   end
    # end

    def start_date
      parameters['start']
    end

    def end_date
      parameters['end']
    end

    def touch_point_name
      parameters["name"]
    end

    def touch_point_source
      GrdaWarehouse::HmisForm.non_confidential
    end

    def responses
      touch_point_source.select(:id, :client_id, :answers, :collected_at, :data_source_id, :assessment_id, :site_id, :staff).
        joins(:hmis_assessment, client: :destination_client).
        where(name: touch_point_name).
        where(collected_at: (start_date..end_date))
    end

    def computed_data
      @computed_data ||= begin
        computed_data = { sections: {} }
        responses.find_each do |response|
          answers = response.answers
          # client_name = response.client.name
          client_id = response.client.destination_client.id
          # date = response.collected_at
          response_id = response.id
          answers[:sections].each do |section|
            title = section[:section_title]
            computed_data[:sections][title] ||= {}
            section[:questions].each do |question|
              question_text = question[:question]
              computed_data[:sections][title][question_text] ||= {}
              computed_data[:sections][title][question_text][client_id] ||= {}
              computed_data[:sections][title][question_text][client_id][response_id] = question[:answer]
            end
          end
        end
        computed_data
      end
    end
  end
end
