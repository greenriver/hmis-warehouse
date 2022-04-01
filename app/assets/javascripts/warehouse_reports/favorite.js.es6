App.StimulusApp.register('favorite', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'id', 'icon']
  }
  static get values() {
    return {
      id: Number
    }
  }
  static get classes() {
    return ['favorite', 'notFavorite']
  }

  favorite(event) {
    event.preventDefault();
    event.stopPropagation();

    const isFavorite = this.iconTarget.classList.contains(this.favoriteClass);

    this.iconTarget.classList.toggle(this.notFavoriteClass, isFavorite);
    this.iconTarget.classList.toggle(this.favoriteClass, !isFavorite);

    $.ajax({
      async: false,
      url: `/api/reports/${this.idValue}/favorite`,
      type: isFavorite ? 'DELETE' : 'PUT',
    }).done((ret) => {
      console.debug('success')
    }).fail((ret) => {
      console.error(['Failed to favorite', ret])

      // revert icon change
      this.iconTarget.classList.toggle(this.notFavoriteClass, !isFavorite);
      this.iconTarget.classList.toggle(this.favoriteClass, isFavorite);
    })
  }



})
