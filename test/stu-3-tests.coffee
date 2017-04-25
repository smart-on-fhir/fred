assert = require "assert"

SchemaUtils = require "../src/helpers/schema-utils.coffee"
profiles = require("../public/profiles/stu3.json").profiles

getNode = (decorated, path) ->
	position = decorated
	segments = path.split(".")
	unless segments.shift() is position.name
		return null
	while (segment = segments.shift())
		newPosition = false
		for child in position.children || []
			if child.name is segment
				position = child
				newPosition = true
				break
		return null unless newPosition
	return position

decorate = (data) ->
	SchemaUtils.decorateFhirData(profiles, data)

assertProperty = (decorated, path, propName, expectedValue) ->
	actualValue = getNode(decorated, path)?[propName]
	assert.equal expectedValue, actualValue

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
		assert.equal decorated.children[1].children[0].children[0].children[0].schemaPath, 
			"Questionnaire.item"
	
	it "should require valid stu3 compliant cardinalities", ->
		decorated = decorate
			resourceType: "Patient"
			name: {family: "dan"}

		assertProperty decorated, "Patient.name.family",
			"fhirType", "string"

	it "should reject invalid stu3 compliant cardinalities", ->
		decorated = decorate
			resourceType: "Patient"
			name: {family: ["bob"]}

		assertProperty decorated, "Patient.name.family",
			"fhirType", undefined