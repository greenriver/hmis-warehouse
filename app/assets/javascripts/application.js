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
//= require vis.min
//= require jquery_ujs
//= require DataTables/datatables.min
//= require handlebars.runtime
//= require select2
//= require bootstrap-datepicker
//= require Chart.bundle.min
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/slider
//= require jquery-ui/widgets/autocomplete
//= require leaflet
//= require leaflet.markercluster/leaflet.markercluster
//= require leaflet-beautify-marker/leaflet-beautify-marker-icon
//= require jquery.periodicalupdater
//= require jquery.updater
//= require jquery.minicolors
//= require jquery.minicolors.simple_form
//= require d3.min
//= require d3-interpolate.v1.min
//= require d3-scale-chromatic.v1.min
//= require topojson.min.js
//= require inputmask/jquery.inputmask.bundle.min
//= require inputmask/inputmask/bindings/inputmask.binding.min
//= require billboard.js/dist/billboard.min
//= require moment.min.js
//= require bootstrap-datetimepicker
//= require stimulus
//= require promise-polyfill/dist/polyfill.min.js

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
//= require cable_ready.cjs.umd
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
//= require TableWithToggleRows
//= require role_table
//= require documentExport.js
//= require file_dropzone

//= require init
