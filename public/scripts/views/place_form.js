$( function () {
	Ts.FormViews.PlaceForm = Backbone.View.extend({
    initialize: function () {
      this.default_place_id = getParameterByName('place_id')
      this.placeData = $('#json\\:place_data').parseJSON() || {}
    },
    render: function () {
			var section = new Ts.FormViews.Section({title: 'Place Editor', name: 'place'})
			if(this.default_place_id) {
				var currentPlace = this.default_place_id
				while (currentPlace > 0) {
					var siblings = this.placeData[currentPlace]
					var collection = new Ts.Places(siblings)
					var placeView = new Ts.FormViews.PlaceEditor({
            selected: currentPlace,
            collection: collection
          })
					section.body.unshift(placeView.render().el)
          currentPlace = siblings[0].parent_id
				}
			} else {
				var collection = new Ts.Places(this.placeData[''])
				var placeView = new Ts.FormViews.PlaceEditPicker({collection: collection})
				section.body.push(placeView.render().el)
			}
      var controls = new Ts.FormViews.PlaceEditControls({
        add: true,
        beforeClick: function () {
          this.options.parentId = this.$el.prev.find('select :selected').val()
        }
      })
			this.$el.append(section.render().el)
      
			return this
		}
  })
  
  Ts.FormViews.PlaceEditPicker = Backbone.View.extend({
    tagName: 'label',
    className: 'placepicker',
    template: _.template($('#form\\:place_edit_picker_template').html()),
    events: {
      'change': function (e) { this.selectPlace(e.target) }
    },
    initialize: function () {
      _.bindAll(this, 'selectPlace')
      this.controls = new Ts.FormViews.PlaceEditControls({parentId: this.collection.at(0).get('parent_id'), add_child: true, add: true, edit: true, delete: true})
      this.options.insertFunction = this.options.insertFunction || 'append'
    },
    render: function () {
      this.$el.html(this.template({
					type: this.collection.first().get('type'),
					places: this.collection.toJSON(),
					selected: this.options.selected,
          disabled: this.options.disabled
			}))
      this.selectPlace(this.$('select'))
      this.$el.append(this.controls.render().el)
			setTimeout("this.$('select').focus()")
      return this
    },
    renderPlaces: function (places, options) {
      options = options || {}
      var parent_id = this.collection.at(0).get('parent_id')
      var view = new this.constructor($.extend({}, this.options, options, {collection: places}))
      view.render().$el.append()
      this.$el.after(view.render().el)
      return this
    },
    selectPlace: function (select_el) {
      var element = $(select_el)
      var placeId = element.children(':selected').attr('value')
      this.$el.nextAll().remove()
      if(placeId) {
        _.extend(this.controls.options, {add_child: true, edit: true, delete: true, placeId: placeId})
        this.load(placeId)
      } else {
        _.extend(this.controls.options, {add_child: false, edit: false, delete: false, placeId: null})
      }
      this.controls.render()
      return this
    },
    load: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      this.$('.indicator').remove()
      this.$el.append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/children/'+parent_id, {
				type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          var places = new Ts.Places(data) 
          if(places.length > 0) {
            this.renderPlaces(places)
            this.$('.indicator').remove()
          } else if (this.collection.get(parent_id).get('child_count') > 0) {
            this.$('.indicator').attr({
              class: 'indicator warning',
              title: this.collection.get(parent_id).get('type').demodulize().titleize() + ' is not available.'
            })
          } else {
            this.$('.indicator').remove()
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          this.$('.indicator').remove()
          if(textStatus != 'abort') alert('Some went wrong!')
        }
      })
      return this
    }
  })
  
  Ts.FormViews.PlaceEditControls = Backbone.View.extend({
    events: {
      'click .add_child': 'clicked',
      'click .add': 'clicked',
      'click .edit': 'clicked',
      'click .delete': 'clicked'
    },
    render: function () {
      this.$el.empty()
      if (this.options.add_child) this.$el.append('<span class="add_child" title="Add Child" />')
      if (this.options.add) this.$el.append('<span class="add" title="Add" />')
      if (this.options.edit) this.$el.append('<span class="edit" title="Edit" />')
      if (this.options.delete) this.$el.append('<span class="delete" title="Delete" />')
      return this
    },
    clicked: function (e) {
      if (this.options.beforeClick) {
        _.bind(this.options.beforeClick, this)(e)
      }
			wizardView = new Ts.FormViews.PlaceWizard({
        model: new Ts.PlaceWizard({place: {id: this.options.placeId, parent_id: this.options.parentId} }),
        onComplete: this.onCompleteCallback
      })
      
      if ($(e.target).hasClass('.add_child')) this.add_child(wizardView)
      if ($(e.target).hasClass('.add')) this.add(wizardView)
      if ($(e.target).hasClass('.edit')) this.edit(wizardView)
      if ($(e.target).hasClass('.delete')) this.delete(wizardView)
    },
    add_child: function (wizardView) {
      wizardView.options.title = "Add Place"
    },
    add: function (wizardView) {
      wizardView.options.title = "Add Place"
    },
    edit: function (wizardView) {
      wizardView.options.title = "Edit Place"
    },
    delete: function () {
      // Delete it
    },
    onCompleteCallback: function () {
      // Refresh parent
    }
  })
  
  // Ts.FormViews.PlaceWizard = Ts.FormViews.WizardView.extend({
  //   
  // })
  // 
  // Ts.FormViews.GenericPlaceForm = Backbone.View.extend({
  //   tagName: 'form',
  //   className: 'rowed',
  //   events: {
  //     'click button': 'doAction',
  //     'keyup': function (e) { if(e.keyCode == 13) this.doAction() }
  //   },
  //   doAction: function (e) {
  //     var action = null
  //     if (e && e.target) {
		// 	  action = $(e.target).attr('action')
  //     } else {
  //       action = this.$('input[action]').attr('action')
  //     }
  //     this.wizard[action](this.model)
  //     return false
		// }
  // })
  // 
  // Ts.FormViews.AddPlaceForm = Ts.FormViews.GenericPlaceForm.extend({
  //   doAction: function () {
  //     
  //   }
  // })
})