// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
/////////////////////
// Vendor libs
////////////////////
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require bootstrap
//= require jquery_ujs
//= require DataTables/datatables.min
//= require handlebars.runtime
//= require select2/dist/js/select2.full.min
//= require bootstrap-datepicker/dist/js/bootstrap-datepicker.min
//= require chart.js/dist/Chart.bundle.min
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/slider
//= require jquery-ui/widgets/autocomplete
//= require leaflet/dist/leaflet
//= require leaflet.markercluster/dist/leaflet.markercluster
//= require beautifymarker/leaflet-beautify-marker-icon
//= require jquery.minicolors
//= require jquery.minicolors.simple_form
//= require d3/dist/d3.min
//= require d3-interpolate/dist/d3-interpolate.min
//= require d3-scale-chromatic/dist/d3-scale-chromatic.min
//= require d3-sankey/dist/d3-sankey.min
//= require topojson-client/dist/topojson-client.min
//= require inputmask/dist/min/jquery.inputmask.bundle.min
//= require inputmask/dist/min/inputmask/bindings/inputmask.binding.min
//= require billboard.js/dist/billboard.min
//= require moment/moment
//= require bootstrap-datetimepicker
//= require stimulus/dist/stimulus.umd
//= require vendor/rfdc/rfdc
//= require promise-polyfill/dist/polyfill.min

//////////////////////////
// App specific code
//////////////////////////
//= require namespace
//= require polyfills
//= require ajax_modal_rails
//= require popovers
//= require util
//= require site_menu
//= require ssm
//= require cha
//= require vispdats
//= require files
//= require selectable_list
//= require viewable_entities
//= require ./cable
//= require ./test_channel
//= require ./init_stimulus
//= require ./background_render
//= require_directory ./admin/client_matches
//= require_directory ./census
//= require_directory ./maps
//= require_directory ./reports
//= require_directory ./rollups
//= require_directory ./sections
//= require_directory ./health
//= require_directory ./weather
//= require_directory ./charts_scatter_by_date
//= require_directory ./dashboards
//= require_directory ./dashboards/clients
//= require_directory ./warehouse_reports/cas
//= require_directory ./warehouse_reports/rrh
//= require_directory ./warehouse_reports/outflow
//= require_directory ./warehouse_reports/performance_dashboards
//= require_directory ./warehouse_reports/homeless_summary_report
//= require_directory ./warehouse_reports
//= require_directory ./d3_charts
//= require_directory ./clients
//= require_directory ./cohorts
//= require_directory ./window/clients
//= require_directory ./users
//= require_directory ./cohorts/viewers
//= require_directory ./cohorts/editors
//= require_directory ./data_quality_reports
//= require affix
//= require list_search
//= require stimulus_select
//= require inactive-session-modal-controller
//= require chart_loader
//= require filter_projects
//= require TableWithToggleRows
//= require role_table
//= require documentExport.js
//= require file_dropzone

//= require init
