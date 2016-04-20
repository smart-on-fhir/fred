assert = require "assert"

SchemaUtils = require "../src/helpers/schema-utils.coffee"
profiles = require "../public/profiles/connect12.json"

describe "STU-3", ->
	it "should decorate nested referenced elements", ->
	decorated = SchemaUtils.decorateFhirData profiles,
		resourceType: "Questionnaire"
		item:
			item: [
				item: [
					item: [text: "test", text: "Test"]
				]
			]
	# console.log JSON.stringify decorated, null, " "
	assert.equal decorated.children[1].children[0].children[0].children[0].schemaPath, 
		"Questionnaire.item"