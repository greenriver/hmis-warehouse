// Report tables can be wider than the printable page. Shrink any table that overflows its container 
// down to fit, via CSS zoom, rather than letting it clip. Relies on PdfGenerator::MEASUREMENT_VIEWPORT
// so this measurement matches what the pdf generator's browser actually uses when it lays out
// the page for print (see HudReports::HudPdfExportConcern#perform).
window.addEventListener('load', function () {
  document.querySelectorAll('.summary-tables .table-responsive').forEach(function (container) {
    var table = container.querySelector('table');
    if (!table) return;
    var naturalWidth = table.scrollWidth;
    var availableWidth = container.clientWidth;
    if (naturalWidth > availableWidth) {
      table.style.zoom = availableWidth / naturalWidth;
    }
  });
});
