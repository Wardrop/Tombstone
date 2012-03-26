$( function () {
	Ts.FormViews.PlaceManagementForm = Ts.View.extend({
    initialize: function () {
      this._super('initialize', arguments)
      this.defaultPlaceId = Ts.getParameterByName('place_id')
      this.placeData = this.getJSON('#json\\:place_data')
    },
    render: function () {
			var section = new Ts.FormViews.Section({title: 'Place Editor', name: 'place'})
			if(this.defaultPlaceId) {
				var currentPlace = this.defaultPlaceId
				while (currentPlace > 0) {
					var siblings = this.placeData[currentPlace]
					var collection = new Ts.Places(siblings)
					var placeView = new Ts.FormViews.PlaceEditPicker({
            selected: currentPlace,
            collection: collection
          })
					section.body.unshift(placeView.el)
          currentPlace = siblings[0].parent_id
				}
			} else {
				var collection = new Ts.Places(this.placeData[''])
				var placeView = new Ts.FormViews.PlaceEditPicker({collection: collection})
				section.body.push(placeView.render().el)
			}
			this.$el.append(section.render().el)
			return this
		}
  })
  
  Ts.FormViews.PlaceEditPicker = Ts.View.extend({
    tagName: 'label',
    className: 'placepicker',
    templateId: 'form:place_picker_template',
    events: {
      change: function () { this.selectPlace() },
      'click .add_child': 'selectAction',
      'click .add': 'selectAction',
      'click .edit': 'selectAction',
      'click .delete': 'selectAction'
    },
    initialize: function () {
      this._super('initialize', arguments)
      this.collection.on('reset', this.render, this)
      this.render()
    },
    render: function () {
      if (this.collection.length > 0) {
        this.$el.html( this.template({
  					type: (this.collection.first()) ? this.collection.first().get('type') : 'unknown',
  					places: this.collection.toJSON(),
  					selected: this.options.selected,
            disabled: this.options.disabled
  			}))
        this.$el.append('<div class="controls" />')
                .append(this.indicator)
        this.selectPlace()
        setTimeout("this.$('select').focus()")
      } else {
        this.remove()
      }
      return this
    },
    renderControls: function () {
      this.$('.controls').empty()
      var selectedPlaceId = this.$(':selected').val()
      if(selectedPlaceId) {
        this.$('.controls').append('<span class="add_child" title="Add Child" />')
                           .append('<span class="add" title="Add" />')
                           .append('<span class="edit" title="Edit" />')
                           .append('<span class="delete" title="Delete" />')
      } else {
        this.$('.controls').append('<span class="add" title="Add" />')
      }
    },
    renderChildPicker: function (places, options) {
      options = options || {}
      var parent_id = this.collection.at(0).get('parent_id')
      var view = new this.constructor($.extend({}, this.options, options, {collection: places}))
      
      this.$el.after(view.el)
      return this
    },
    selectPlace: function (placeId) {
      var element = this.$('select')
      if (placeId == undefined) {
        placeId = element.children(':selected').attr('value')
      } else {
        element.val(placeId)
      }
      this.$el.nextAll().remove()
      if(placeId) {
        this.loadChildren(placeId)
      }
      this.renderControls()
      return this
    },
    loadChildren: function (parent_id) {
      places = new Ts.Places
      this.renderChildPicker(places)
      places.fetch({url: '/place/'+parent_id+'/children'})
      return this
    },
    selectAction: function (e) {
      if ($(e.target).hasClass('add_child')) this.add_child()
      if ($(e.target).hasClass('add')) this.add()
      if ($(e.target).hasClass('edit')) this.edit()
      if ($(e.target).hasClass('delete')) this.delete()
    },
    add_child: function () {
      this.prepareWizard()
      this.wizardView.model.set('place', new Ts.Place({status: 'available'}))
      this.wizardView.model.set('title', 'Add Place')
      this.wizardView.showPlaceForm()
    },
    add: function () {
      this.prepareWizard()
      var placeData = this.wizardView.model.get('place').toJSON()
      this.wizardView.model.set('place', new Ts.Place({type: placeData.type, status: 'available'}))
      this.wizardView.model.set('title', 'Add Place')
      this.wizardView.showPlaceForm()
    },
    edit: function () {
      this.prepareWizard()
      this.wizardView.model.set('title', 'Edit Place')
      this.wizardView.showPlaceForm()
    },
    delete: function () {
      var place = this.collection.get(this.$(':selected').val())
      place.destroy({
        wait: true,
        success: function (data) {
          if(data.success != false) this.refresh()
        }
      })
    },
    prepareWizard: function () {
      var place = this.collection.get(this.$(':selected').val())
			this.wizardView = new Ts.FormViews.PlaceWizard({
        model: new Ts.PlaceWizard({
          place: place || new Ts.Place({parent_id: this.collection.at(0).get('parent_id')})
        }),
        onComplete: _.bind(this.refresh, this)
      })
      this.wizardView.render()
    },
    refresh: function () {
      var place = this.collection.get(this.$(':selected').val())
      var placeId = (place) ? place.get('id') : null
      var parentId = (place) ? place.get('parent_id') : 0
      this.collection.fetch({
        url: '/place/'+parentId+'/children',
        success: _.bind(function () {
          this.selectPlace(placeId)
        }, this)
      })
    }
  })
  
  Ts.FormViews.PlaceWizard = Ts.WizardViews.Wizard.extend({
    showPlaceForm: function () {
      placeForm = new Ts.FormViews.PlaceForm({
        model: this.model.get('place'),
        wizard: this,
        indicator: this.indicator,
        errorBlock: this.errorBlock
      })
      this.model.set({currentPage: placeForm})
    },
    savePlace: function (place) {
      place.on('sync:done', function (type, model, data) {
        if(data.success != false) {
				  this.close()
          this.onComplete(this.model.get('place'))
				}
      }, this)
      place.save()
    }
  })
  
  Ts.FormViews.PlaceForm = Ts.WizardViews.GenericForm.extend({
    templateId: 'place_form:place_form_template'
  })
})