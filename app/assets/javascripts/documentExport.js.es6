const initialState = {
  open: false,
  status: 'pending',
  downloadUrl: null,
};

$(() => {
  const $modal = $('#pjax-modal');

  let state = { ...initialState };
  const setState = (newState) => {
    state = {
      ...state,
      ...newState,
    };
  };

  $modal.on('hidden.bs.modal', () => {
    setState(initialState);
  });

  const updateDisplay = (newState) => {
    setState(newState);
    // console.info('set state display', state);
    if (state.open) {
      $modal.modal('show');
    }
    let title = $('.j-document-export-title').text();
    $modal.find('.modal-title').text(title);
    let body = $('.j-document-export-body').html();
    $modal.find('.modal-body').html(body);
    $modal.attr('data-status', state.status);
    $modal.find('.j-download-link').attr('href', state.downloadUrl);
  };

  let interval = null;
  const resetInterval = () => {
    if (interval) {
      clearInterval(interval);
    }
    interval = null;
  };

  const handleSubmission = (postResult) => {
    if (!postResult || !postResult.pollUrl) {
      return updateDisplay({ status: 'error' });
    }
    updateDisplay(postResult);
    const pollTime = 3000;
    const maxPollCount = 400;
    let pollCount = 0;
    interval = setInterval(() => {
      pollCount += 1;
      if (pollCount > maxPollCount || state.status !== 'pending' || !state.open) {
        clearInterval(interval);
        return;
      }
      $.get(postResult.pollUrl, (pollResult) => {
        updateDisplay(pollResult);
      }).catch(() => {
        updateDisplay({ status: 'error' });
      });
    }, pollTime);
  };

  const handleDownloadClick = (evt) => {
    const $node = $(evt.currentTarget);
    resetInterval();
    updateDisplay({ open: true });

    const formData = {
      type: $node.data('type'),
      query_string: $node.data('query-string'),
    };

    const xhr = $.ajax({
      url: $('.j-document-export-body').data('url'),
      type: 'POST',
      data: formData,
    });
    xhr.then(handleSubmission).catch(() => {
      updateDisplay({ status: 'error' });
    });
  };

  $(document).on('click', '.j-document-exports', handleDownloadClick);
});
