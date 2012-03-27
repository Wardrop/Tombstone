$( function () {
  Ts.FormViews.Section = Ts.View.extend({
    tagName: 'section',
    templateId: 'form:section_template',
    initialize: function () {
      this.body = []
      if (body = this.options.body) {
        this.body = (body.constructor == Array) ? body : [body]
      }
    },
    render: function () {
      this.$el.html(this.template(this.options))
      _.each(this.body, function (element) {
        this.$('div').append(element)
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
			this.role_name = this.options.role_name || this.role_type.split('_').join(' ').titleize()
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
          name: this.role_type + '_action',
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
			wizardView = new Ts.RoleWizardViews.WizardView({
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
			wizardView = new Ts.RoleWizardViews.WizardView({
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
      this.$el.html(this.template({name: this.options.name, options: this.options.values}))
      var viewport = this.$('.viewport')
      var height = viewport.find('li').outerHeight() || 34
      viewport.css({height: height});
      if (Object.keys(this.options.values).length <= 1)
        this.$el.addClass('no_dropdown')
      else
        this.$el.removeClass('no_dropdown')
      this.selectButton(this.options.selected || this.$('input:first')[0].name)
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
    selectButton: function(selectedName) {
      var list = this.$('.viewport > ul')
      selected = list.find('li > input[name='+selectedName+']').parent()
      list.css({top: -selected.position().top})
		  list.children('li').removeClass('selected')
		  selected.addClass('selected')
		},
    onSelectButton: function (e) {
			var target = e.currentTarget
      var button = $(target).children('input')
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
  
  Ts.FormViews.PlacePicker = Ts.View.extend({
    tagName: 'label',
    className: 'placepicker',
    templateId: 'form:place_picker_template',
    events: {
      'change': 'selectPlace'
    },
    initialize: function () {
      _.bindAll(this, 'selectPlace')
      this.options.insertFunction = this.options.insertFunction || 'append'
    },
    render: function () {
      this.$el.html(this.template({
        type: this.collection.first().get('type'),
        places: this.collection.toJSON(),
        selected: this.options.selected,
        disabled: this.options.disabled
			}))
			setTimeout("this.$('select').focus()")
      return this
    },
    renderPlaces: function (places, options) {
      options = options || {}
      var view = new Ts.FormViews.PlacePicker($.extend({}, this.options, options, {collection: places}))
      this.$el.parent()[this.options.insertFunction](view.render().el)
      return this
    },
    selectPlace: function (e) {
      var target = $(e.target)
      var placeId = target.children(':selected').attr('value')
      this.$el.nextAll().remove()
      if(placeId) {
        if(target.data('placeType') == 'section') {
          this.nextAvailable(placeId)
        } else {
          this.load(placeId)
        }
      }
      return this
    },
    load: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
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
    },
    nextAvailable: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      this.$('.indicator').remove()
      this.$el.append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
        type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          if (data && Object.keys(data).length > 0) {
            _.each(data, function (places, selected_id) {
              this.renderPlaces(new Ts.Places(places), {selected: selected_id})
            }, this)
            this.$('.indicator').remove()
          } else {
            this.$('.indicator').attr({
              class: 'indicator warning',
              title: this.collection.get(parent_id).get('type').demodulize().titleize() +
                ' does not contain any available places.'
            })
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert(jqXHR.responseText)
          this.$('.indicator').remove()
        }
      })
      return this
    }
    // loadWithAncestors: function (id) {
    //   this.lastRequest && this.lastRequest.abort()
    //   this.$el.append('<div class="indicator loading" />')
    //   this.lastRequest = $.ajax('/place/ancestors/'+id, {
    //     type: 'GET',
		//     dataType: 'json',
    //     data: {include_self: true},
    //     success: _.bind(function (data, textStatus, jqXHR) {
    //       var lastParent = id
    //       _.each(data, function (placeList) {
    //         this.renderPlaces(new Ts.Places(placeList), {selected: lastParent, insertFunction: 'prepend'})
    //         lastParent = placeList[0].parent_id
    //       }, this)
    //     }, this),
    //     error: function (jqXHR, textStatus, errorThrown) {
    //       // TODO
    //       if(textStatus != 'abort') alert('Some went wrong!')
    //     },
    //     complete: _.bind(function () {
    //       this.$('.indicator').remove()
    //     }, this)
    //   })
    //   return this
    // }
  })
  
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
			this.wizardView = new Ts.WizardViews.PlaceWizard({
        model: new Ts.PlaceWizard({
          place: place || new Ts.Place({parent_id: this.collection.at(0).get('parent_id')})
        }),
        onComplete: _.bind(this.refresh, this)
      })
      this.wizardView.render()
    },
    refresh: function () {
      console.log('refreshing')
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
  
  Ts.FormViews.AllocationForm = Ts.View.extend({
		events: {
			'submit' : 'onSubmit'
		},
		onSubmit: function () {
			return false
		},
		initialize: function () {
			this.firstSection = $(this.el).children('section').first()
			this.placeData = $('#json\\:place_data').parseJSON() || {}
			this.allocationData = $('#json\\:allocation_data').parseJSON() || {}
			this.indicator = $('<div class="indicator" />')
			this.render()
		},
		render: function () {
			this.renderRoles()
			this.renderPlaces()
			this.renderActions()
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
				var currentPlace = place_id
				while (currentPlace > 0) {
					var siblings = this.placeData[currentPlace]
					var collection = new Ts.Places(siblings)
					var placeView = new Ts.FormViews.PlacePicker({
            selected: currentPlace,
            collection: collection,
            disabled: !this.allocationData.id
          })
					section.body.unshift(placeView.render().el)
          currentPlace = siblings[0].parent_id
				}
        if (placeView.options.disabled) {
          section.body.unshift($('<input type="hidden" name="place[]" value="'+place_id+'" />')[0])
        }
			} else {
				var collection = new Ts.Places(this.placeData[''])
				var placeView = new Ts.FormViews.PlacePicker({collection: collection})
				section.body.push(placeView.render().el)
			}
			this.firstSection.before(section.render().el)
			return this
		},
		renderActions: function () {
			this.multibutton = new Ts.FormViews.Multibutton({
				name: 'submit',
				values: this.options.states,
				actions: {
					default: _.bind(function (el) {
						this.submit(el.attr("name"))
					}, this)
				}
			})
			var section = new Ts.FormViews.Section({
				title: 'Actions',
				body: this.multibutton.render().el
			})
			$(this.el).append(section.render().el)
		},
		submit: function (status) {
			var data = this.formData()
			data.status = status
			this.indicator.attr('class', 'indicator loading').insertAfter(this.multibutton.el)
			this.hideFormErrors()
			if(this.lastRequest && this.lastRequest.state() == 'pending') {
				if (confirm('The last submit operation has not yet completed. Would you like to abort the last submit operations?')) {
					this.lastRequest.abort()
				} else {
					return false
				}
			}
			this.lastRequest = $.ajax(this.el.action, {
				type: 'POST',
				data: data,
				success: _.bind( function (data, textStatus, jqXHR) {
					if(data.success == false) {
						this.showFormErrors(data.form_errors)
						this.indicator.detach()
					} else {
						this.indicator.attr('class', 'indicator success')
						window.location = data.redirectTo
					}
				}, this),
				error: _.bind( function (jqXHR, textStatus, errorThrown) {
					this.indicator.detach()
					switch(textStatus) {
						case 'error':
							try {
								this.showFormErrors($.parseJSON(jqXHR.responseText).exception.capitalize())
							} catch (err) {
								this.showFormErrors("Server error encountered: "+errorThrown+"\n"+jqXHR.responseText)
							}
							break;
						default:
							this.showFormErrors("Error encountered: "+errorThrown)
					}
				}, this)
			})
		},
		formData: function () {
			var data = $(this.el).serializeObject()
			_.each(this.roleBlocks, function (roleBlock, role_type) {
				data[role_type] = roleBlock.getJSON()
		  })
			return data
		},
		showFormErrors: function (errors) {
			var container = $('<ul class="error_block" />')
			errors = (errors.constructor == String) ? [errors] : errors
      
      var iterateErrors = function (prefix, errors) {
        var array = []
				_.each(errors, function (error, field) {
					if (error.constructor == Array) {
						_.each(error, function (message) {
							errorObj = {}
              errorObj[field] = message
							array = array.concat( iterateErrors(prefix, errorObj) )
						})
					} else if (error.constructor == Object) {
						array = array.concat(iterateErrors((prefix && prefix + " -> ") + field.split('_').join(' ').titleize(), error))
					} else {
            field = (field) ? field.split('_').join(' ').titleize() : ''
            array.push((prefix && prefix + " -> ") + field.split('_').join(' ').titleize() + " " + error)
					}
				})
				return array
			}
			iterateErrors('', errors).forEach( function (error) {
        container.append($('<li />').text(error))
      })
			
			_.each(errors, function (value, field) {
				if (value.length > 0) this.$('[name='+field+']').addClass('field_error')
			})
	
			container.css({display: 'none'}).prependTo(this.el).slideDown(300)
			this.$(':first').scrollTo(300, -10);
		},
		hideFormErrors: function () {
			this.$('.error_block').remove()
			this.$('[name]').removeClass('field_error')
		}
	})
})