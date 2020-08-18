###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::ExportsController < Hic::BaseController
    def show
      @partial = versions.detect { |v| v == params[:version] } || versions.last
    end

    def create
      @partial = versions.detect { |v| v == export_params[:version] } || versions.last
      @date = export_params[:date].to_date
    end

    private

    def versions
      [
        'fy2017',
        'fy2019',
      ]
    end

    def export_params
      params.require(:filter).
        permit(
          [
            :version,
            :date,
          ],
        )
    end
  end
end
