// window.App.Form = window.App.Form || {}

// App.Form.Select2Input = class Select2Input {
//   constructor(element, options={}) {
//     let field = null
//     if (typeof(element) === 'string') {
//       field = document.getElementById(element)
//     } else {
//       field = element
//     }
//     if (!field) {
//       console.debug(`Select2Input could not find element: ${element}`)
//     } else {
//       this.$select = $(field)
//       this.$select2Container = this.$select.next('.select2-container')

//       // Add options based on use-case
//       // CoCs get special functionality "My Coc (MA-500)" becomes MA-500 when selected
//       if (field.classList.contains('select2-parenthetical-when-selected')) {
//         options.templateSelection = (selected) => {
//           if (!selected.id) {
//             return selected.text
//           }
//           // use the parenthetical text to keep the select smaller
//           const matched = selected.text.match(/\((.+?)\)/)
//           if (matched && !matched.length == 2) {
//             return selected.text
//           } else if (matched && matched.length) {
//             return matched[1]
//           } else {
//             return selected.text
//           }
//         }
//       }

//       if (field.classList.contains('select2-id-when-selected')) {
//         options.templateSelection = (selected) => {
//           if (!selected.id) {
//             return selected.text
//           }
//           // use the code to keep the select smaller
//           return selected.id
//         }
//       }

//       // Add select all functionality if has `multiple` attribute
//       if (field.hasAttribute('multiple')) {
//         options.closeOnSelect = false
//         this.$select.select2(options)
//         if (! this.$select.data('disableSelectAll')) {
//           this.initToggleSelectAll()
//         }
//       }
//       else {
//         // Init!
//         this.$select.select2(options)
//       }

//       // Parenthetical
//       $(".select2-search__field").attr('aria-label', 'Search')

//       // Trigger toggle select of sub-items for opt-groups
//       this.$select.on('select2:open', this.initToggleChildren.bind(this))
//       this.$select.on('select2:select', this.updateOptGroupState)
//       this.$select.on('select2:unselect', this.updateOptGroupState)
//       this.$select.on('select2:open', this.updateOptGroupState)
//       this.$select.on('select2:close', this.removeToggleChildren.bind(this))
//     }
//   }

//   selectAllHtml() {
//     let text = 'all'
//     if (this.someItemsSelected() || this.allItemsSelected()) {
//       text = 'none'
//     }
//     return `<span class='mr-2'>Select ${text}</span>`
//   }

//   numberOfSelectedItems() {
//     return this.$select.find('option:selected').length
//   }

//   someItemsSelected() {
//     return this.numberOfSelectedItems() && !this.allItemsSelected()
//   }

//   allItemsSelected() {
//     return this.numberOfSelectedItems() === this.$select.find('option').length && this.$select.find('option').length > 0
//   }

//   toggleSelectAll(isManualChange=false) {
//     if (!isManualChange) {
//       this.$select.find('option').prop('selected', !this.allItemsAreSelected)
//       this.allItemsAreSelected = !this.allItemsAreSelected
//     } else {
//       if (this.someItemsSelected() || this.allItemsSelected()) {
//         this.allItemsAreSelected = true
//       } else {
//         this.allItemsAreSelected = false
//       }
//     }
//     this.$select.trigger('change')

//     // Update DOM element to reflect selections
//     const $selectAllLink = this.$formGroup.find('.select2-select-all')
//     // this.$select2Container[classAction]('all-selected')
//     let html = this.selectAllHtml()
//     if (this.allItemsSelected() || this.numberOfSelectedItems()) {
//       html = this.selectAllHtml()
//     }
//     $selectAllLink.html(html)
//   }

//   // called on every open
//   initToggleChildren(e) {
//     const self = this
//     $('body').on('click', '.select2-results__group', function(e){
//       let group_ids = self.optionGroupOptionIds(self.optionsForGroup($(this)))
//       let previously_selected = self.$select.find(':selected').map(function () {
//         return this.value
//       }).get()
//       // uncheck
//       if ($(this).hasClass('j-all-selected')) {
//         let now_selected = previously_selected.filter(id => !group_ids.includes(id))
//         self.$select.val(now_selected)
//         self.$select.trigger('change.select2')
//         self.optionsForGroup($(this)).each(function () {
//           $(this).attr('aria-selected', 'false')
//         })
//         $(this).removeClass('j-all-selected')
//       }
//       // check
//       else {
//         // select anything within the opt group and the previously selected items
//         self.$select.val(previously_selected.concat(group_ids))
//         self.$select.trigger('change.select2')

//         // Trigger change.select2 should really do this, but it doesn't, so we manually set the selected nature
//         self.optionsForGroup($(this)).each(function () {
//           $(this).attr('aria-selected', 'true')
//         })
//         // update the optgroup to reflect selected state
//         $(this).addClass('j-all-selected')
//       }
//     })
//   }

//   updateOptGroupState(e) {
//     // FIXME: the open event is firing before the drop-down is populated completely,
//     // so the optgroups can't get populated with select none when fully selected
//     if (e.type == 'select2:open') {
//       // if triggered by open, just remove all indication of state, and rebuild later
//       $(this).find('.j-all-selected').removeClass('j-all-selected')
//     }
//     else {
//       // If triggered by select, clear the parent state and rebuild later
//       $(e.params.originalEvent.delegateTarget)
//         .closest('.select2-dropdown')
//         .find('.j-all-selected')
//         .removeClass('j-all-selected')
//     }

//     // If options are selected, update state of all optgroups to match selection
//     if ($(this).select2('data').length && $(this).find('optgroup').length) {
//       let selected_ids = $(this).select2('data').map(function(e){
//         return e.id
//       })

//       $($(this).select2('data')).each(function () {
//         let sibs = $(this.element).parent().children().get().map(function (e) {
//           return $(e).val()
//         })

//         let all_selected = sibs.every(val => selected_ids.includes(val))
//         let optgroup = $(`#${this._resultId}`).parent().siblings('.select2-results__group')
//         if(all_selected) {
//           optgroup.addClass('j-all-selected')
//         }
//       })
//     }
//   }

//   optionsForGroup(opt_group) {
//     return opt_group.next('ul').find('li.select2-results__option')
//   }

//   selectedOptionsForGroup(opt_group) {
//     return opt_group.next('ul').find('li.select2-results__option[aria-selected=true]')
//   }

//   allOptionsSelected(opt_group) {
//     let group_ids = this.optionGroupOptionIds(this.optionsForGroup(opt_group))
//     let selected_ids = this.optionGroupOptionIds(this.selectedOptionsForGroup(opt_group))
//     return group_ids.every(val => selected_ids.includes(val))
//   }

//   optionGroupOptionIds(options) {
//     return options.map(function () {
//       return this.id.split('-').pop()
//     }).get()
//   }

//   removeToggleChildren(e){
//     $('body').off('click', '.select2-results__group')
//   }

//   noneSelected() {
//     return (this.$formGroup.find('select').val() === 0) ||
//       (this.$select.select2('data').length === 0)
//   }

//   initToggleSelectAll() {
//     // Init here
//     const hasItemsSelectedOnInit = this.numberOfSelectedItems()
//     this.$formGroup = this.$select.closest('.form-group')
//     this.$formGroup.addClass('select2-wrapper')
//     const $label = this.$formGroup.find('> label')
//     const $labelWrapper = $("<div class='select2__label-wrapper'></div>")
//     // Add select all/none link to select2 input
//     $labelWrapper.append($(`
//       <div class="select2-select-all j-select2-select-all">
//         ${this.selectAllHtml()}
//       </div>
//     `))
//     // only add it if we don't already have it
//     if(this.$formGroup.find('.j-select2-select-all').length == 0) {
//       $label.prependTo($labelWrapper)
//       this.$formGroup.prepend($labelWrapper)
//     }

//     // Init events on select2
//     // Trigger toggle on manual update: 'select2:select select2:unselect
//     // Trigger toggle on select all/ none click: '.j-select2-select-all'
//     this.$select.closest('.form-group')
//       .on('click', '.j-select2-select-all', this.toggleSelectAll.bind(this, false))
//     this.$select.on('select2:select select2:unselect', this.toggleSelectAll.bind(this, true))

//     // Initial state based on existing options
//     this.allItemsAreSelected = this.numberOfSelectedItems()
//   }
// }
