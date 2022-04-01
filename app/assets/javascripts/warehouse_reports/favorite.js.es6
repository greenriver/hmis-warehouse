App.StimulusApp.register('favorite', class extends Stimulus.Controller {
  static get targets() {
    return ['icon']
  }
  static get values() {
    return {
      id: Number
    }
  }
  static get classes() {
    return ['favorite', 'notFavorite']
  }

  toggleIcon(wasFavorite) {
    this.iconTarget.classList.toggle(this.notFavoriteClass, wasFavorite);
    this.iconTarget.classList.toggle(this.favoriteClass, !wasFavorite);
  }

  favorite(event) {
    event.preventDefault();
    event.stopPropagation();

    const isFavorite = this.iconTarget.classList.contains(this.favoriteClass);

    $.ajax({
      async: false,
      url: `/api/reports/${this.idValue}/favorite`,
      type: isFavorite ? 'DELETE' : 'PUT',
    }).done((ret) => {
      this.toggleIcon(isFavorite)
    }).fail((ret) => {
      console.error(['Failed to favorite', ret])
    })
  }



})
