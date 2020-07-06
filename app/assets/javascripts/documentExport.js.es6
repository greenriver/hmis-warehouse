'use strict';

var setupNode = function (_idx, e) {
  const $node = $(e);
  const $modal = $('#j-document-export-modal');
  const url = $modal.data('url');

  const formData = {
    type: $node.data('type'),
    query_string: $node.data('query-string'),
  };
  // console.info(formData);
  const submitForm = function () {
    const xhr = $.ajax({
      url,
      type: 'POST',
      data: formData,
    });
    const cancel = function () {
      xhr.abort();
    };
    return { xhr, cancel };
  };

  $node.on('click', function () {
    $modal.find('.modal-body').html('<p class="lead">Processing...</p>');
    $modal.modal('show');
    const ajax = submitForm();
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
