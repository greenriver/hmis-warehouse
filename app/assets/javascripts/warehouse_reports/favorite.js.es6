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
    const route = isFavorite ? 'unfavorite' : 'favorite';

    this.toggleIcon(isFavorite);

    $.ajax({
      url: `/api/reports/${this.idValue}/${route}`,
      method: 'PUT'
    })
    .done((ret) => {
      console.debug(`Successful ${route} ${this.idValue}`);
    })
    .fail((ret) => {
      console.error([`Failed to ${route} ${this.idValue}`, ret]);
      // Undo icon change
      this.toggleIcon(!isFavorite);
    })
  }



})
