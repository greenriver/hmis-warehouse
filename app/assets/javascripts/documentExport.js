'use strict';

var setupNode = function (_idx, e) {
  var $node = $(e);
  var $modal = $('#j-document-export-modal');
  var url = $modal.data('url');

  var formData = {
    type: $node.data('type'),
    query_string: $node.data('query-string'),
  };
  // console.info(formData);
  var submitForm = function () {
    var xhr = $.ajax({
      type: 'POST',
      url: url,
      data: formData,
    });
    var cancel = function () {
      xhr.abort();
    };
    return { xhr: xhr, cancel: cancel };
  };

  $node.on('click', function () {
    $modal.find('.modal-body').html('<p class="lead">Processing...</p>');
    $modal.modal('show');
    var ajax = submitForm();
    ajax.xhr
      .then(function (resp) {
        $modal.find('.modal-body').html(resp);
      })
      .catch(function () {
        $modal
          .find('.modal-body')
          .html('<p class="lead text-danger">An Error Occured, please try again</p>');
      });
    $modal.on('hidden.bs.modal', () => {
      ajax.cancel();
      $modal.find('.modal-body').html('');
    });
  });
};

$(function () {
  $('.j-document-exports').each(setupNode);
});
