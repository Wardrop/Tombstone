// JavaScript Document

Ts.Roles = Backbone.Collection.extend({
	model: Ts.Role
})

Ts.Contacts = Backbone.Collection.extend({
	model: Ts.Contact,
  url: '/person/contacts'
})

Ts.People = Backbone.Collection.extend({
	model: Ts.Person,
  url: '/person/all'
})

Ts.Places = Backbone.Collection.extend({
  url: '/places'
})