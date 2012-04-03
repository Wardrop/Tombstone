window.indicators = []

$( function () {
  Ts.FormViews.Section = Ts.View.extend({
    tagName: 'section',
    templateId: 'form:section_template',
    initialize: function () {
      this.body = []
      if (this.options.body) {
        body = this.options.body
        this.body = (body.constructor == Array) ? body : [body]
      }
    },
    render: function () {
      this.$el.html(this.template(this.options))
      _.each(this.body, function (element) {
        this.$('> div').append(element)
      }, this)
      return this
    }
  })
  Ts.FormViews.RoleBlock = Ts.View.extend({
    templateId: 'form:role_block_template',
    events: {
      'click div.row_block' : 'changeRole',
      'click a.add' : 'addRole',
      'click a.delete' : 'removeRole'
    },
    initialize: function () {
      this.group = this.options.group || {}
      this.role_type = this.options.role_type
			this.role_name = this.options.role_name && this.role_type.split('_').join(' ').titleize()
      _.bindAll(this, 'render', 'addRole', 'changeRole', 'onCompleteCallback')
    },
    render: function () {
      this.$el.empty()
      if (this.model) {
        this.$el.html(this.template({model: (this.model) ? this.model.recursiveToJSON() : null}))
      } else {
        values = {add: 'Add'}
        actions = {add: this.addRole}
        _.each(this.group, function (roleBlock) {
          if(roleBlock != this) {
            values['use_'+roleBlock.role_type] = 'Use '+roleBlock.role_name.demodulize().titleize()
            actions['use_'+roleBlock.role_type] = _.bind( function () {
              this.useRole(roleBlock)
            }, this)
          }
        }, this)
        var multibutton = new Ts.FormViews.Multibutton({
          values: values,
          actions: actions
        })
        this.$el.append(multibutton.render().el)
      }
  		return this
    },
    getJSON: function () {
      return (this.model && this.model.recursiveToJSON()) || (this.use && {type: this.role_type, use: this.use}) || null
    },
    addRole: function () {
      this.use = null
      wizard = new Ts.Wizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
			wizardView = new Ts.WizardViews.RoleWizard({
        model: wizard,
        onComplete: this.onCompleteCallback
      })
      $('body').prepend(wizardView.render().el)
    },
    useRole: function (roleBlock) {
      this.use = roleBlock.role_type
    },
    changeRole: function () {
      // clonedModel = new Ts.Role({
      //   type: this.role_type,
      //   person: this.model.get("person").clone(),
      //   residential_contact: this.model.get("residential_contact").clone(),
      //   mailing_contact: this.model.get("mailing_contact").clone()
      // })
      // clonedModel.get("person").set({id: null})
      wizard = new Ts.Wizard({title: "Change "+this.role_name, role: this.model})
			wizardView = new Ts.WizardViews.RoleWizard({
        model: wizard,
        onComplete: this.render
      })
      $('body').prepend(wizardView.render().el)
    },
    removeRole: function () {
      if(confirm('Are you sure you want to remove this object?')) {
        this.model = null
        this.render()
      }
      return false
    },
    onCompleteCallback: function (role) {
      this.model = role
      this.render()
    }
  })
  
  Ts.FormViews.Multibutton = Ts.View.extend({
    tagName: 'span',
    className: 'multibutton',
    templateId: 'form:multibutton_template',
    events: {
      'click span.dropdown_button' : 'toggleList',
      'click li' : 'onSelectButton'
    },
    initialize: function () {
      _.bindAll(this, 'hideList', 'showList', 'keydownHideEvent')
    },
    render: function () {
      this.$el.css({display: 'none'}).html(this.template(this.options))
      var viewport = this.$('.viewport')
      // Because the height of an element can't be retrieved until it's inserted into the DOM, we wrap the sizing
      // logic in a 10ms timeout, so a call like ```multibutton.render().el``` will be rendered correctly.
      setTimeout(_.bind( function () {
        this.$el.css({display: ''})
        var height = viewport.find('li').outerHeight() || 34
        viewport.css({height: height});
      }, this))
      if (Object.keys(this.options.values).length <= 1) {
        this.$el.addClass('no_dropdown')
      } else {
        this.$el.removeClass('no_dropdown')
      }
      this.$el.addClass(this.options.class)
      this.$('li:first').addClass('selected')
      if (this.options.selected) this.selectButton(this.options.selected)
      this.hideList()
      
  		return this
    },
    toggleList: function () {
      var viewport = this.$('.viewport')
      viewport.hasClass('show') ? this.hideList() : this.showList()
    },
    showList: function () {
      this.autoAdjustHeight()
      this.$('.viewport').addClass('show')
      var list = this.$('.viewport ul')
      var window_bottom = $(window).scrollTop() + $(window).height();
			var list_bottom = list.offset().top + list.outerHeight();
			if((list_bottom + 10) > window_bottom) {
			  list.css({top: -(list.outerHeight() - list.find('li').outerHeight())})
			} else {
			  list.css({top: -list.children('li.selected').position().top})
			}
			// If we don't wrap this binding in a delay, it'll fire directly after this event which is not what we want.
			_.delay(function (self) { $(document).click(self.hideList); }, 1, this);
			$(window).blur(this.hideList)
			$(document).keydown(this.keydownHideEvent)
    },
    hideList: function () {
      var list = this.$('.viewport ul')
      list.css({top: -list.children('li.selected').position().top})
      this.$('.viewport').removeClass('show')
      $(document).unbind('click', this.hideList)
			$(window).unbind('blur', this.hideList)
			$(document).unbind('keydown', this.keydownHideEvent)
    },
    autoAdjustHeight: function () {
      var viewport = this.$('.viewport')
      var height = viewport.find('li').outerHeight()
      if (height > 0) viewport.css({height: height})
    },
    selectButton: function(selectedItem) {
      var list = this.$('.viewport > ul')
      if (selectedItem.constructor == String) {
        selected = list.find('li > [name='+selectedItem+']').parent()
      } else {
        selected = $(selectedItem)
      }
      list.css({top: -selected.position().top})
		  list.children('li').removeClass('selected')
		  selected.addClass('selected')
		},
    onSelectButton: function (e) {
			var target = e.currentTarget
      var button = $(target).children()
			var selectedName = button.attr('name')
      this.selectButton(selectedName)
			if (this.options.actions && this.options.actions[selectedName]) {
				var result = this.options.actions[selectedName](button)
			} else if (this.options.actions && this.options.actions['default']) {
				var result = this.options.actions['default'](button)
			}
      this.hideList()
			return (result == true) ? true : false
    },
    keydownHideEvent: function (e) {
      if (e.keyCode == 27) this.hideList();
    }
  })
  
  Ts.FormViews.Multilink = Ts.FormViews.Multibutton.extend({
    templateId: 'form:multilink_template',
    events: {
      'click span.dropdown_button' : 'toggleList',
      'click li': function (e) { this.selectButton(e.currentTarget) }
    }
  })
  
  // Ts.FormViews.PlacePicker = Ts.View.extend({
  //   tagName: 'label',
  //   className: 'placepicker',
  //   templateId: 'form:place_picker_template',
  //   events: {
  //     'change': 'selectPlace'
  //   },
  //   initialize: function () {
  //     _.bindAll(this, 'selectPlace')
  //   },
  //   render: function () {
  //     this.$el.html(this.template({
  //       type: this.collection.first().get('type'),
  //       places: this.collection.toJSON(),
  //       selected: this.options.selected,
  //       disabled: this.options.disabled
  //      }))
  //     return this
  //   },
  //   renderPlaces: function (places, options) {
  //     options = options || {}
  //     var view = new Ts.FormViews.PlacePicker($.extend({}, this.options, options, {collection: places}))
  //     this.$el.parent().append(view.render().el)
  //     setTimeout("view.$('select').focus()")
  //     return this
  //   },
  //   selectPlace: function (e) {
  //     var target = $(e.target)
  //     var placeId = target.children(':selected').attr('value')
  //     this.$el.nextAll().remove()
  //     if(placeId) {
  //       if(target.data('placeType') == 'section') {
  //         this.nextAvailable(placeId)
  //       } else {
  //         this.load(placeId)
  //       }
  //     }
  //     return this
  //   },
  //   load: function (parent_id) {
  //     this.lastRequest && this.lastRequest.abort()
  //     this.$el.append('<div class="indicator loading" />')
  //     this.lastRequest = $.ajax('/place/children/'+parent_id, {
  //        type: 'GET',
  //        dataType: 'json',
  //       success: _.bind(function (data, textStatus, jqXHR) {
  //         var places = new Ts.Places(data) 
  //         if(places.length > 0) {
  //           this.renderPlaces(places)
  //           this.$('.indicator').remove()
  //         } else if (this.collection.get(parent_id).get('child_count') > 0) {
  //           this.$('.indicator').attr({
  //             class: 'indicator warning',
  //             title: this.collection.get(parent_id).get('type').demodulize().titleize() + ' is not available.'
  //           })
  //         } else {
  //           this.$('.indicator').remove()
  //         }
  //       }, this),
  //       error: function (jqXHR, textStatus, errorThrown) {
  //         // TODO
  //         this.$('.indicator').remove()
  //         if(textStatus != 'abort') alert('Some went wrong!')
  //       }
  //     })
  //     return this
  //   },
  //   nextAvailable: function (parent_id) {
  //     this.lastRequest && this.lastRequest.abort()
  //     this.$('.indicator').remove()
  //     this.$el.append('<div class="indicator loading" />')
  //     this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
  //       type: 'GET',
  //        dataType: 'json',
  //       success: _.bind(function (data, textStatus, jqXHR) {
  //         if (data && Object.keys(data).length > 0) {
  //           _.each(data, function (places, selected_id) {
  //             this.renderPlaces(new Ts.Places(places), {selected: selected_id})
  //           }, this)
  //           this.$('.indicator').remove()
  //         } else {
  //           this.$('.indicator').attr({
  //             class: 'indicator warning',
  //             title: this.collection.get(parent_id).get('type').demodulize().titleize() +
  //               ' does not contain any available places.'
  //           })
  //         }
  //       }, this),
  //       error: function (jqXHR, textStatus, errorThrown) {
  //         // TODO
  //         if(textStatus != 'abort') alert(jqXHR.responseText)
  //         this.$('.indicator').remove()
  //       }
  //     })
  //     return this
  //   }
  // })
  
  Ts.FormViews.PlaceForm = Ts.View.extend({
    initialize: function () {
      this._super('initialize', arguments)
      this.defaultPlaceId = Ts.getParameterByName('place_id')
      this.placeData = this.getJSON('#json\\:place_data')
    },
    render: function () {
			var section = new Ts.FormViews.Section({title: 'Place Editor', name: 'place'})
			if (this.defaultPlaceId) {
				for (var i = 0; places = this.placeData[i]; i++) {
				  var selected = (this.placeData[i+1]) ? this.placeData[i+1][0].parent_id : this.defaultPlaceId
					var placeView = new Ts.FormViews.PlaceEditPicker({
            selected: selected,
            collection: new Ts.Places(places)
          })
					section.body.push(placeView.render().el)
				}
			} else {
				var collection = new Ts.Places(this.placeData[0])
				var placeView = new Ts.FormViews.PlaceEditPicker({collection: collection})
				section.body.push(placeView.render().el)
			}
			this.$el.append(section.render().el)
			return this
		}
  })
  
  Ts.FormViews.PlacePicker = Ts.View.extend({
    tagName: 'label',
    className: 'placepicker',
    templateId: 'form:place_picker_template',
    events: {
      change: function () { this.selectPlace() }
    },
    initialize: function () {
      this.options.url || (this.options.url = function (id) { return '/place/'+id+'/children/available' })
      this._super('initialize', arguments)
      this.collection.on('reset', function () {
        this.render()
        this.selectPlace()
      }, this)
      this.render()
    },
    render: function () {
      if (this.collection.length > 0) {
        this.$el.html(this.template ({
  					type: (this.collection.first()) ? this.collection.first().get('type') : 'unknown',
  					places: this.collection.toJSON(),
  					options: this.options
  			}))
      } else {
        this.$el.detach()
      }
      this.$el.append(this.indicator)
      return this
    },
    renderChildPicker: function (places, options) {
      options = options || {}
      var selectedPlace = this.collection.get(this.$(':selected').val())
      if (places.length == 0 && selectedPlace.get('child_count') > 0) {
        this.indicator.css({display: ''}).attr({
          class: 'indicator warning',
          title: selectedPlace.get('type').demodulize().titleize() +
            ' does not contain any available places.'
        })
      }
      var view = new this.constructor($.extend({}, this.options, options, {collection: places}))
      this.$el.after(view.el)
      setTimeout(function () { view.$('select').focus() })
      return view
    },
    selectPlace: function (placeId) {
      var element = this.$('select')
      if (placeId == undefined) {
        placeId = element.val()
      } else {
        element.val(placeId)
      }
      this.$el.nextAll().remove()
      if(placeId) {
        if(this.options.nextAvailableFrom && this.options.nextAvailableFrom == element.data('placeType')) {
          this.nextAvailable(placeId)
        } else {
          this.loadChildren(placeId)
        }
      }
      return this
    },
    loadChildren: function (parent_id) {
      places = new Ts.Places
      this.bindToSync(places)
      places.fetch({
        url: this.options.url(parent_id),
        complete: _.bind( function () {
          this.unbindFromSync(places)
          this.renderChildPicker(places)
        }, this)
      })
      return this
    },
    nextAvailable: function (parent_id) {
      var dummy = new Backbone.Collection
      this.bindToSync(dummy)
      Backbone.sync('read', dummy, {
        url: '/place/'+parent_id+'/next_available',
        success: _.bind(function (data, textStatus, jqXHR) {
          if (data && Object.keys(data).length > 0) {
            var lastPickerView = null
            for(var i=0; data[i]; i++) {
              var selected_id = (data[i+1]) ? data[i+1][0].parent_id : null
              lastPickerView = (lastPickerView || this).renderChildPicker(new Ts.Places(data[i]), {selected: selected_id})
            }
            lastPickerView.collection.all( function (place) {
              if (place.get('child_count') < 1) {
                lastPickerView.selectPlace(place.get('id'))
                return false
              } else {
                return true
              }
            })
            
            lastPickerView.$el.change()
          } else {
            this.indicator.attr({
              class: 'indicator warning',
              title: this.collection.get(parent_id).get('type').demodulize().titleize() +
                ' does not contain any available places.'
            })
          }
        }, this)
      })
      return this
    }
  })
  
  Ts.FormViews.PlaceEditPicker = Ts.FormViews.PlacePicker.extend({
    events: {
      change: function () { this.selectPlace() },
      'click .add_child': 'selectAction',
      'click .add': 'selectAction',
      'click .edit': 'selectAction',
      'click .delete': 'selectAction'
    },
    initialize: function () {
      this.options.url || (this.options.url = function (id) { return '/place/'+id+'/children' })
      this._super('initialize', arguments)
      this.collection.onModelEvents = function () {}
    },
    render: function () {
      this._super('render', arguments)
      this.renderControls()
      return this
    },
    renderControls: function () {
      if (this.$el.children('select').length == 0) return false
      if (this.$('.controls').length == 0) {
        this.indicator.before('<div class="controls" />')
      } else {
        this.$('.controls').empty()
      }
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
    selectPlace: function () {
      this._super('selectPlace', arguments)
      this.renderControls()
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
      this.wizardView.model.set('place', new Ts.Place({
        parent_id: this.collection.get(this.$(':selected').val()).get('id'),
        status: 'available'
      }))
      this.wizardView.model.set('title', 'Add Place')
      this.wizardView.showPlaceForm()
    },
    add: function () {
      this.prepareWizard()
      var placeData = this.wizardView.model.get('place').toJSON()
      this.wizardView.model.set('place', new Ts.Place({
        parent_id: this.collection.at(0).get('parent_id'),
        type: placeData.type,
        status: 'available'
      }))
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
      this.bindToSync(place)
      place.destroy({
        wait: true,
        success: _.bind( function (data) {
          this.refresh()
        }, this),
        complete: _.bind( function () {
          this.unbindFromSync(place)
        }, this)
      })
    },
    prepareWizard: function () {
      var place = (
        this.collection.get(this.$(':selected').val()) ||
        new Ts.Place({parent_id: this.collection.at(0).get('parent_id'), type: this.collection.at(0).get('type')})
      )
			this.wizardView = new Ts.WizardViews.PlaceWizard({
        model: new Ts.PlaceWizard({place: place}),
        onComplete: _.bind(this.refresh, this)
      })
      this.wizardView.render()
    },
    refresh: function () {
      var place = this.collection.get(this.$(':selected').val())
      var placeId = (place) ? place.get('id') : null
      var parentId = (place && place.get('parent_id')) || this.collection.at(0).get('parent_id') || 0
      this.collection.fetch({
        url: '/place/'+parentId+'/children',
        success: _.bind(function () {
          this.selectPlace(placeId)
        }, this)
      })
    }
  })
  
  Ts.FormViews.AllocationForm = Ts.View.extend({
		events: {
			'submit' : 'onSubmit'
		},
		initialize: function () {
		  this._super('initialize', arguments)
			this.firstSection = $(this.el).children('section').first()
			this.placeData = $('#json\\:place_data').parseJSON() || {}
			this.allocationData = $('#json\\:allocation_data').parseJSON() || {}
			this.bindToSync(
			  this.eventReceiver = _.clone(Backbone.Events)
			)
			this.render()
		},
		onSubmit: function () {
			return false
		},
		render: function () {
			this.renderRoles()
			this.renderPlaces()
			this.renderActions()
			this.errorBlock.prependTo(this.$el)
			return this
		},
		renderRoles: function () {
			this.roleBlocks = {}
			var roleData = {}
			_.each(this.allocationData.roles, function (role) {
				roleData[role.type] = role
			})
			_.each(this.options.valid_roles, function (type) {
				var role;
				if (roleData[type]) {
					role = new Ts.Role({
						type: type,
						person: new Ts.Person(roleData[type].person),
						residential_contact: new Ts.Contact(roleData[type].residential_contact),
						mailing_contact: new Ts.Contact(roleData[type].mailing_contact)
					})
				}
				var roleBlock = new Ts.FormViews.RoleBlock({role_name: type, role_type: type, group: this.roleBlocks, model: role})
				this.roleBlocks[type] = roleBlock
				var section = new Ts.FormViews.Section({
					title: type.demodulize().titleize(),
					name: type,
					body: roleBlock.el
				})
				this.firstSection.before(section.render().el)
			}, this)
			_.each(this.roleBlocks, function (block) { block.render() })
			return this
		},
		renderPlaces: function () {
			var section = new Ts.FormViews.Section({title: 'Location', name: 'place'})
			if(place_id = this.allocationData.place_id) {
				var places;
				for (var i = 0; places = this.placeData[i]; i++) {
				  var selected = (this.placeData[i+1]) ? this.placeData[i+1][0].parent_id : this.allocationData.place_id
					var placeView = new Ts.FormViews.PlacePicker({
            selected: selected,
            collection: new Ts.Places(places),
            nextAvailableFrom: 'section',
            disabled: !this.allocationData.id
          })
					section.body.push(placeView.render().el)
				}
        if (placeView.options.disabled) {
          section.body.unshift($('<input type="hidden" name="place[]" value="'+place_id+'" />')[0])
        }
			} else {
				var collection = new Ts.Places(this.placeData[0])
				var placeView = new Ts.FormViews.PlacePicker({collection: collection, nextAvailableFrom: 'section',})
				section.body.push(placeView.render().el)
			}
			this.firstSection.before(section.render().el)
			return this
		},
		renderActions: function () {
			this.multibutton = new Ts.FormViews.Multibutton({
				values: this.options.states,
				actions: {
					default: _.bind(function (el) {
						this.submit(el.attr("name"))
					}, this)
				}
			})
			var section = new Ts.FormViews.Section({
				title: 'Actions',
				body: [this.multibutton.render().el, this.indicator]
			})
			$(this.el).append(section.render().el)
		},
		submit: function (status) {
			var data = this.formData()
			data.status = status
			this.hideErrors()
			if(this.lastRequest && this.lastRequest.state() == 'pending') {
				if (confirm('The last submit operation has not yet completed. Would you like to abort the last submit operation?')) {
					this.lastRequest.abort()
				} else {
					return false
				}
			}
			
			var method = (this.allocationData.id && this.allocationData.type == this.options.type) ? 'update' : 'create'
			var emulateJSON = Backbone.emulateJSON
			try {
			  Backbone.emulateJSON = true
  			this.lastRequest = Backbone.sync(method, this.eventReceiver, {
          url: this.el.action,
          data: data,
          success: _.bind( function (data, textStatus, jqXHR) {
  					this.indicator.attr('class', 'indicator success')
  					window.location = data.redirectTo
  				}, this)
        })
      } finally {
        Backbone.emulateJSON = emulateJSON
      }
		},
		formData: function () {
			var data = $(this.el).serializeObject()
			_.each(this.roleBlocks, function (roleBlock, role_type) {
				data[role_type] = roleBlock.getJSON()
		  })
			return data
		}
	})
})