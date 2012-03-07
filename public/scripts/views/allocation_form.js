$( function () {
  Ts.FormViews.NewAllocationForm = Backbone.View.extend({
    events: {},
    initialize: function () {
      this.firstSection = $(this.el).children('section').first()
      if (this.options.placeData) this.options.placeData = []
      if (this.options.roleData) this.options.roleData = {}
      this.renderRoles()
      this.renderPlaces()
    },
    renderRoles: function () {
      var roles = []
      var roleData = this.options.roleData
      _.each(this.options.roles, function (type) {
        var role
        if (roleData[type]) {
          role = new Ts.Role({
            type: type,
            person: new Ts.Person(roleData[type].person),
            residential_contact: new Ts.Contact(roleData[type].residential_contact),
            mailing_contact: new Ts.Contact(roleData[type].mailing_contact)
          })
        }
        roles.push(role)
        var roleBlock = new Ts.FormViews.RoleBlock({role_name: type, role_type: type, model: role})
        var section = new Ts.FormViews.Section({
          title: type.demodulize().titleize(),
          name: type,
          body: roleBlock.render().el
        })
        this.firstSection.before(section.render().el)
      }, this)
      return this
    },
    renderPlaces: function () {
      var placeData = this.options.placeData
      var section = new Ts.FormViews.Section({title: 'Location', name: 'place'})
      if(placeData.length == 0) {
        section.body.push(new Ts.Places())
      } else {
        _.each(placeData, function (placeList) {
          var collection = new Ts.Places(placeList.collection)
          var placeView = new Ts.FormViews.PlacesView({selected: placeList.selected, collection: collection})
          section.body.push(placeView.render().el)
        }, this)
      }
      this.firstSection.before(section.render().el)
      return this
    },
    submit: function (e) {
      
    },
    formData: function () {
      var data = $(this.el).serializeObject()
      _.each(this.roles, function (role, name) {
        if (role.model) {
          data[name] = role.model.recursiveToJSON()
        }
      })
      return data
    },
    showFormErrors: function (errors) {
      var container = $('<ul class="error_block" />')
      errors = (errors.constructor == String) ? [errors] : errors
      var iterateErrors = function (ul, errors) {
        _.each(errors, function (error, field) {
          if (error.constructor == Array) {
            _.each(error, function (message) {
              errorObj = {}; errorObj[field] = message
              ul.append($('<li />').text(field.split('_').join(' ').titleize()))
              ul.append(iterateErrors($('<ul />'), errorObj))
            })
          } else if (error.constructor == Object) {
            ul.append(iterateErrors($('<ul />'), error))
          } else {
            ul.append($('<li />').text(error))
          }
        })
        return ul
      }
      iterateErrors(container, errors)
      
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