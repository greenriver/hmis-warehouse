module Api::Health::Claims::Patients
  class BaseController < ApplicationController
    before_action :require_can_view_or_edit_client_health!
    before_action :set_patient
    before_action :load_data
    
    def index
      render json: @data
    end

    def load_data
      raise NotImplementedError
    end

    # group the data by date, then sum each column
    def group_by_date_and_sum_by_category(data)
      sums = Hash.new(0)
      data.group_by do |row|
        Date.new(row.year, row.month, 01)
      end.map do |date, data|
        data = data.map do |row|
          row.attributes.with_indifferent_access.
          except(:id, :medicaid_id, :year, :month)
        end.each_with_object(sums) do |row, sums|
            row.each do |k, v|
              sums[k] += v
            end
          end
        {date: date}.merge(data)
      end
    end

    # group the data by date
    def group_by_date(data)
      data.group_by do |row|
        Date.new(row.year, row.month, 01)
      end.map do |date, data|
        data = data.map do |row|
          {date: date}.merge(row.attributes.with_indifferent_access.
          except(:id, :medicaid_id, :year, :month)).map do |k,v|
            v ||= 0
            [k, v]
          end.to_h
        end.first
        
      end
    end

    protected def scope
      source.where(medicaid_id: @patient.medicaid_id)
    end

    protected def set_patient
      @patient = ::Health::Patient.find(params[:patient_id].to_i)
    end

    protected def require_can_view_or_edit_client_health!
      can_view = can_view_client_health? || can_edit_client_health?
      return true if can_view
      not_authorized!      
    end
  end
end