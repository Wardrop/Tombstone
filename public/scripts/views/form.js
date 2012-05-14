$( function () {
  Ts.FormViews.Section = Ts.View.extend({
    tagName: 'section',
    templateId: 'form:section_template',
    divClass: 'padded',
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
        this.$el.html(this.template({model: this.model}))
      } else {
        var items = [{name: 'add', value: 'Add'}]
        var actions = {add: this.addRole}
        _.each(this.group, function (roleBlock) {
          if(roleBlock != this) {
            items.push({
              name: 'use_'+roleBlock.role_type,
              value: 'Use '+roleBlock.role_name.demodulize().titleize()
            })
            actions['use_'+roleBlock.role_type] = _.bind( function () {
              this.useRole(roleBlock)
            }, this)
          }
        }, this)
        var multibutton = new Ts.FormViews.Multibutton({
          items: items,
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
      wizard = new Ts.RoleWizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
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
      wizard = new Ts.Wizard({title: "Change "+this.role_name, role: this.model})
			wizardView = new Ts.WizardViews.RoleWizard({
        model: wizard,
        onComplete: this.onCompleteCallback
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
      'click li' : 'onSelectItem'
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
      if (this.options.items.length <= 1) {
        this.$el.addClass('no_dropdown')
      } else {
        this.$el.removeClass('no_dropdown')
      }
      this.$el.addClass(this.options['class'])
      this.$('li:first').addClass('selected')
      if (this.options.selected) this.selectItem($(this.options.selected, this.$('li')).first().parent())
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
    selectItem: function(selectedItem) {
      var list = this.$('.viewport > ul')
      if (selectedItem.constructor == String) {
        selected = list.find('li > [name='+selectedItem+']').parent()
      } else {
        selected = $(selectedItem)
      }
      setTimeout(function () {
        list.css({top: -selected.position().top})
      })
		  list.children('li').removeClass('selected')
		  selected.addClass('selected')
		},
    onSelectItem: function (e) {
			var listItem = e.currentTarget
      var button = $(listItem).children()
      this.selectItem(listItem)
			if (this.options.actions) {
        if (this.options.actions[button.data('action')]) {
				  var result = this.options.actions[button.data('action')](button)
			  } else if (this.options.actions['default']) {
				  var result = this.options.actions['default'](button)
			  }
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
      'click li': function (e) { this.selectItem(e.currentTarget) }
    }
  })
  
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
          'class': 'indicator warning',
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
              'class': 'indicator warning',
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
      if ($(e.target).hasClass('delete')) this['delete']()
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
    'delete': function () {
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
      
  Ts.FormViews.PhotosEditor = Ts.View.extend({
    templateId: 'form:photo_editor_template',
    events: {
      'change [type=file]': 'fileChanged',
      'click .delete': 'delete'
    },
    initialize: function () {
      this._super('initialize', arguments)
      this.place_id = this.options.place_id
      this.photos = this.options.photos || []
      this.uploadForm = $('<form action="/photos/'+this.place_id+'" method="post" target="photo_form_frame" enctype="multipart/form-data"></form>')
    },
    render: function () {
      this.$el.html(this.template())
      $('body').append(this.uploadForm)
      this.$('[type=file]').after(this.indicator.addClass('loading'))
      this.$el.prepend(this.errorBlock)
      setTimeout( _.bind( function () {
        this.$('iframe').load(_.bind(this.onLoad, this))
      }, this), 50)
      this.delegateEvents()
      return this
    },
    fileChanged: function (e) {
      var fileInput = this.$(e.target)
      var originalParent = fileInput.parent()
      this.indicator.css({display: ''})
      $(fileInput).appendTo(this.uploadForm)
      this.uploadForm.submit()
      $(fileInput).prependTo(originalParent)
    },
    onLoad: function () {
      this.indicator.css({display: 'none'})
      var result = $.parseJSON(this.$('iframe').contents().text())
      if (result) {
        this.photos.push(result)
      }
      this.render()
    },
    'delete': function (e) {
      e.stopPropagation()
      e.preventDefault()
      if(confirm('Are you sure you want to delete this photo?')) {
        Backbone.sync('delete', this.eventReceiver, {
          url: e.target.href,
          data: {},
          success: _.bind(function () {
            _.each(this.photos, function (photo, idx) {
              if (photo.id == $(e.target).data('id')) {
                this.photos.splice(idx, 1)
              }
            }, this)
            this.render()
          }, this)
        })
      }
    }
  })
  
  Ts.FormViews.AllocationView = Ts.View.extend({
    stateMap: {provisional: 'Provision', pending: 'Pend', approved: 'Approve',
               interred: 'Inter', completed: 'Complete', deleted: 'Delete'},
    initialize: function () {
      this._super('initialize', arguments)
      this.allocationData = $('#json\\:allocation_data').parseJSON() || {}
      this.permittedStates = $('#json\\:permitted_states').parseJSON() || {}
      this.errorBlock.prependTo(this.el)
    },
    render: function () {
      var items = _(this.permittedStates).without(['provisional', 'deleted']).map(function (state) {
        return {name: state, value: this.stateMap[state] || state.titleize(), action: 'updateStatus'}
      }, this)
      items[items.length - 1].className = 'with_bottom_divider'
      if (this.allocationData.type == 'interment') items.push({name: 'multiple_interment', value: 'Multiple Interment'})
      if (this.allocationData.type == 'reservation' && this.allocationData.status != 'deleted') items.push({name: 'inter', value: 'Inter'})
      items.push(
        {name: 'edit', value: 'Edit'},
        {name: 'delete', value: 'Delete'},
        {name: 'print', value: 'Print'}
      )
      
      var multibutton = new Ts.FormViews.Multibutton({
        selected: '[name=edit]',
        items: items,
        actions: {
          edit: _.bind(function () {
            window.location = '/'+this.allocationData.type+'/'+this.allocationData.id+'/edit'
          }, this),
          inter: _.bind(function () {
            window.location = '/interment/'+this.allocationData.id+'/new'
          }, this),
          multiple_interment: _.bind(function () {
            window.location = '/interment/?place_id='+this.allocationData.place_id
          }, this),
          'delete': function () {
            if (confirm('Are you sure you want to delete this interment?')) {
              $('<form method="post" />').append($('<input type="hidden" name="_method" value="delete" />')).submit()
            }
          },
          print: function () {
            window.print()
          },
          updateStatus: _.bind( function (button) {
            console.log('updating status')
            var status = $(button).attr('name')
            Backbone.sync('update', this.eventReceiver, {
              url: '/'+this.allocationData.type+'/'+this.allocationData.id+'/status',
              data: {status: status},
              success: _.bind( function (data, textStatus, jqXHR) {
      					this.indicator.css({display: ''}).attr('class', 'indicator success')
      					window.location = data.redirectTo
      				}, this)
            })
          }, this),
          'default': function () {
            alert('This function is not currently implemented.')
          }
        }
      })
          
			var section = new Ts.FormViews.Section({
				title: 'Actions',
				body: [multibutton.render().el, this.indicator]
			})
			$(this.el).append(section.render().el)
      return this
		}
  })
  
  Ts.FormViews.AllocationForm = Ts.View.extend({
		initialize: function () {
		  this._super('initialize', arguments)
			this.firstSection = $(this.el).children('section').first()
			this.placeData = $('#json\\:place_data').parseJSON() || {}
			this.allocationData = $('#json\\:allocation_data').parseJSON() || {}
			this.render()
		},
		render: function () {
			this.renderRoles()
			this.renderPlaces()
      if (this.allocationData.type == 'interment' && this.allocationData.id) {
        this.renderPhotoEditor()
      }
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
            mailing_contact: roleData[type].mailing_contact && new Ts.Contact(roleData[type].mailing_contact)
          })
          role.get('person').valid(true)
          role.get('residential_contact').valid(true)
          if (role.get('mailing_contact')) role.get('mailing_contact').valid(true)
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
				var placeView = new Ts.FormViews.PlacePicker({collection: collection, nextAvailableFrom: 'section'})
				section.body.push(placeView.render().el)
			}
			this.firstSection.before(section.render().el)
			return this
		},
    renderPhotoEditor: function () {
      var section = new Ts.FormViews.Section({title: 'Location', name: 'place'})
      var photosEditor = new Ts.FormViews.PhotosEditor({photos: this.allocationData.photos, place_id: this.allocationData.place_id})
      section.body.push(photosEditor.render().el)
      section.divClass = 'v_padded'
      this.$el.append(section.render().el)
    },
		renderActions: function () {
			this.multibutton = new Ts.FormViews.Multibutton(_.extend({
				actions: {
          'submitWithStatus': _.bind(function (el) {
						this.submit({status: $(el).attr('name')})
					}, this),
					'default': _.bind(function (el) {
						this.submit()
					}, this)
				}
			}, this.options.multibutton))
			var section = new Ts.FormViews.Section({
				title: 'Actions',
				body: [this.multibutton.render().el, this.indicator]
			})
			$(this.el).append(section.render().el)
		},
		submit: function (data) {
			var data = _.extend(this.formData(), data)
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
  					this.indicator.css({display: ''}).attr('class', 'indicator success')
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