$( function () {
	Ts.FormViews.PlaceForm = Ts.View.extend({
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
  
  Ts.FormViews.PlaceEditPicker = Ts.View.extend({
    tagName: 'label',
    className: 'placepicker',
    templateId: 'form:place_picker_template',
    events: {
      change: function (e) { this.selectPlace() }
    },
    initialize: function () {
      this._super('initialize', arguments)
      this.collection.on('sync:before', function () { this.$el.append(this.indicator) }, this)
      this.collection.on('sync:error', function () { this.$el.append(this.errorBlock) }, this)
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
        this.controls = new Ts.FormViews.PlaceEditControls({
          parentId: this.collection.at(0).get('parent_id'),
          add_child: true,
          add: true,
          edit: true,
          delete: true,
          onComplete: _.bind( function (place) {
            this.collection.fetch({
              success: function () {
                console.log(self.collection)
                self.render()
              },
              data: {parent_id: place.get('parent_id')}
            })
          }, this)
        })
        this.selectPlace()
        this.$el.append(this.controls.render().el).append(this.indicator)
        setTimeout("this.$('select').focus()")
      } else {
        this.remove()
      }
      return this
    },
    renderChildPicker: function (places, options) {
      options = options || {}
      var parent_id = this.collection.at(0).get('parent_id')
      var view = new this.constructor($.extend({}, this.options, options, {collection: places}))
      
      this.$el.after(view.el)
      return this
    },
    selectPlace: function () {
      var element = this.$('select')
      var placeId = element.children(':selected').attr('value')
      this.$el.nextAll().remove()
      if(placeId) {
        _.extend(this.controls.options, {add_child: true, edit: true, delete: true, placeId: placeId})
        this.loadChildren(placeId)
      } else {
        this.indicator.css({display: 'none'})
        _.extend(this.controls.options, {add_child: false, edit: false, delete: false, placeId: null})
      }
      this.controls.render()
      return this
    },
    loadChildren: function (parent_id) {
      places = new Ts.Places
      this.renderChildPicker(places)
      places.fetch({url: '/place/'+parent_id+'/children'})
      
      // this.get('/place/children/'+parent_id, function (data) {
      //   var places = new Ts.Places(data) 
      //   if(places.length > 0) {
      //     this.renderChildPicker(places)
      //   } else if (this.collection.get(parent_id).get('child_count') > 0) {
      //     this.indicator.removeClass('loading').addClass('warning')
      //       .attr('title', this.collection.get(parent_id).get('type').demodulize().titleize() + ' is not available.')
      //       .appendTo(this.$el)
      //   }
      // })
      return this
    }
    // loadWithAncestors: function (id) {
    //   this.get('/places/ancestors/'+id, function (data) {
    //     var lastParent = id
    //     _.each(data, function (placeList) {
    //       this.renderChildPicker(new Ts.Places(placeList), {selected: lastParent, insert: 'before'})
    //       lastParent = placeList[0].parent_id
    //     }, this)
    //   })
    // }
  })
  
  Ts.FormViews.PlaceEditControls = Ts.View.extend({
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
			this.wizardView = new Ts.FormViews.PlaceWizard({
        model: new Ts.PlaceWizard({
          place: new Ts.Place({id: this.options.placeId, parent_id: this.options.parentId, name: 'default'})
        }),
        onComplete: this.onComplete
      })
      if ($(e.target).hasClass('add_child')) this.add_child()
      if ($(e.target).hasClass('add')) this.add()
      if ($(e.target).hasClass('edit')) this.edit()
      if ($(e.target).hasClass('delete')) this.delete()
      this.wizardView.render()
    },
    add_child: function () {
      wizard = this.wizardView.model
      wizard.get('place').set({id: undefined, parent_id: wizard.get('place').get('id')})
      wizard.set('title', 'Add Place')
      this.wizardView.showAddPlaceForm()
    },
    add: function () {
      wizard = this.wizardView.model
      wizard.get('place').set({id: undefined})
      wizard.set('title', 'Add Place')
      this.wizardView.showAddPlaceForm()
    },
    edit: function () {
      wizard = this.wizardView.model
      wizard.set('title', 'Edit Place')
      this.wizardView.showEditPlaceForm()
    },
    delete: function () {
      // Delete it
    },
    onComplete: function () {}
  })
  
  Ts.FormViews.PlaceWizard = Ts.WizardViews.Wizard.extend({
    showAddPlaceForm: function () {
      placeForm = new Ts.FormViews.AddPlaceForm({
        model: this.model.get('place'),
        wizard: this,
        indicator: this.indicator,
        errorBlock: this.errorBlock
      })
      this.model.set({currentPage: placeForm})
    },
    createPlace: function (place) {
      place.on('sync:done', function (type, model, data) {
        if(data.success != false) {
				  this.close()
          this.onComplete(this.model.get('place'))
				}
      }, this)
      place.save()
    }
  })
  
  Ts.FormViews.AddPlaceForm = Ts.WizardViews.GenericForm.extend({
    templateId: 'place_form:add_place_form_template'
  })
})