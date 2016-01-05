Freezer = require "freezer-js"

state = new Freezer
	ui: 
		status: "ready"
	resource: null
	profiles: null

module.exports = state