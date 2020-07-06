const initialState = {
  open: false,
  status: 'pending',
  linkUrl: null,
};

$(() => {
  const $modal = $('#j-document-export-modal');

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
    console.info('set state display', state);
    if (state.open) {
      $modal.modal('show');
    }
    $modal.attr('data-status', state.status);
    $modal.find('.j-link').attr('href', state.linkUrl);
  };

  let interval = null;
  const resetInterval = () => {
    if (interval) {
      clearInterval(interval);
    }
    interval = null;
  };

  const handleSubmission = (postResult) => {
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
      }).catch((e) => {
        console.error(e);
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
      url: $modal.data('url'),
      type: 'POST',
      data: formData,
    });
    xhr.then(handleSubmission).catch((e) => {
      console.error(e);
      updateDisplay({ status: 'error' });
    });
  };

  $(document).on('click', '.j-document-exports', handleDownloadClick);
});
