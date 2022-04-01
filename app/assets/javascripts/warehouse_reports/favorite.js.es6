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
    return ["favorite", "notFavorite"]
  }

  //FIXME... it should show up in "favorites" tab right away

  favorite(event) {
    event.preventDefault();
    event.stopPropagation();
    
    
    const isFavorite = this.iconTarget.classList.contains(this.favoriteClass);
    
    this.iconTarget.classList.toggle(this.notFavoriteClass, isFavorite);
    this.iconTarget.classList.toggle(this.favoriteClass, !isFavorite);

    let data = { type: isFavorite ? "unfavorite" : "favorite" }
    console.log(`${data.type}-ing report ${this.idValue}`);
    $.ajax({
      async: false,
      url: `/api/reports/${this.idValue}/favorite`,
      type: 'PUT',
      data: data,
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
