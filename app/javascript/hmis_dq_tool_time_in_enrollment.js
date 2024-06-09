// Because this needs to be inlined for PDF generation, we don't actually import from
// the base chart, we include the base chart file and use globalThis
// import HmisDqToolChart from './hmis_dq_tool_chart'

class HmisDqToolTimeInEnrollment extends HmisDqToolChart {
  build_chart() {
    return this.chart = bb.generate({
      bindto: this.chart_selector,
      size: {
        height: 250
      },
      data: {
        json: this.data['data'],
        type: "bar",
        color: this._colors
      },

      axis: {
        x: {
          type: "category",
          categories: this.data['labels']
        }
      }
    });
  }
};

globalThis.HmisDqToolTimeInEnrollment = HmisDqToolTimeInEnrollment;
