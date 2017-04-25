assert   = require "assert"
fs       = require "fs"
filePath = require "path"
profiles = require("../public/profiles/dstu2.json").profiles

SchemaUtils = require "../src/helpers/schema-utils.coffee"

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

getChildBySchemaPath = (children, schemaPath) ->
	(child for child in children when child.schemaPath is schemaPath)

decorate = (data) ->
	SchemaUtils.decorateFhirData(profiles, data)

assertProperty = (decorated, path, propName, expectedValue) ->
	actualValue = getNode(decorated, path)?[propName]
	assert.equal expectedValue, actualValue

assertValue = (decorated, path, expectedValue) ->
	assertProperty(decorated, path, "value", expectedValue)

assertChildCount = (decorated, path, expectedCount) ->
	actualCount = getNode(decorated, path)?.children?.length
	assert.equal expectedCount, actualCount

assertRoundTrip = (data) ->
	decorated = decorate(data)
	fhir = SchemaUtils.toFhir(decorated)
	assert.deepEqual(fhir, data)

describe "schema utils: fhir conversion", ->

	it "should convert a value", ->
		assertRoundTrip
			resourceType: "Patient"

	it "should convert an array of values", ->
		assertRoundTrip
			resourceType: "HumanName"
			family: ["name1", "name2"]

	it "should convert an object", ->
		assertRoundTrip
			resourceType: "Narrative"
			text: {status: "generated"}

	it "should convert an array of objects", ->
		assertRoundTrip
			resourceType: "Patient"
			name: [{use: "official"}, {use: "nickname"}]

	it "should convert multitype values", ->
		assertRoundTrip
			resourceType: "Patient"
			deceasedBoolean: true

	it "should convert unknown structures", ->
		assertRoundTrip
			resourceType: "Patient"
			unknown1: [{unknown2: "unknown3"}]
			unknown4: ["unknown5"]

	it "should validate valid primitive types", ->
		decorated = decorate
			resourceType: "Patient"
			birthDate: "2014-01-01"

		[fhir, errCount] = SchemaUtils.toFhir(decorated, true)
		assert.equal errCount, 0

	it "should invalidate invalid primitive types", ->
		decorated = decorate
			resourceType: "Patient"
			birthDate: "not a date"

		[fhir, errCount] = SchemaUtils.toFhir(decorated, true)
		assert.equal errCount, 1

	it "should invalidate empty nodes", ->
		decorated = decorate
			resourceType: "Patient"
			name: [{given: [""]}]
			
		[fhir, errCount] = SchemaUtils.toFhir(decorated, true)
		assert.equal errCount, 1


describe "schema utils: decoration", ->

	it "should decorate a Domain Resource", ->
		decorated = decorate
			resourceType: "Patient"
		assertChildCount decorated, "Patient", 1
		assertProperty decorated, "Patient.resourceType",
			"value", "Patient"

	it "should decorate a backbone element", ->
		decorated = decorate
			resourceType: "Patient"
			animal: { species: { coding: [
				system: "http://hl7.org/fhir/animal-species"
				code: "canislf"
				display: "Dog"
			]}}
		assertChildCount decorated, "Patient.animal.species.coding.Coding", 3
		assertValue decorated, 
			"Patient.animal.species.coding.Coding.code", "canislf"

	it "should decorate a primative type", ->
		decorated = decorate
			resourceType: "Patient"
			gender: "female"
		assertValue decorated, "Patient.gender", "female"
		assertProperty decorated, "Patient.gender", "fhirType", "code"

	it "should decorate an array of primative types", ->
		decorated = decorate
			resourceType: "HumanName"
			family: ["name1", "name2"]
		assertChildCount decorated, "HumanName.family", 2

	it "should decorate a complex type", ->
		decorated = decorate
			resourceType: "Patient"
			name: [{ use: "official"}]
		
		assertValue decorated, 
			"Patient.name.HumanName.use", "official"
		assertProperty decorated, 
			"Patient.name.HumanName.use", "fhirType", "code"

	it "should decorate a multi-type value", ->
		decorated = decorate
			resourceType: "Patient"
			deceasedBoolean: true
		assertProperty decorated,  "Patient.deceasedBoolean", 
			"schemaPath", "Patient.deceased[x]"
		assertProperty decorated,  "Patient.deceasedBoolean", 
			"fhirType", "boolean"

	it "should decorate a complex-type multi-type value", ->
		decorated = decorate
			resourceType: "Observation"
			component: [
				valueQuantity: {"value": 109}
			]
		assertProperty decorated, 
			"Observation.component.component.valueQuantity.value", "value", 109


	it "should decorate unknown values", ->
		decorated = decorate
			resourceType: "Patient"
			notAnElement: true

		assertProperty decorated, "Patient.notAnElement", true
		assertProperty decorated, "Patient.notAnElement",
			"fhirType", undefined


	it "should decorate unknown arrays", ->
		decorated = decorate
			resourceType: "Patient"
			notAnElement: ["a", "b"]

		assertProperty decorated, "Patient.notAnElement", null
		assertProperty decorated, "Patient.notAnElement",
			"fhirType", undefined

	it "should decorate unknown objects", ->
		decorated = decorate
			resourceType: "Patient"
			notAnElement:
				sub1: "a"
				sub2: "b"

		assertProperty decorated, "Patient.notAnElement", null
		assertProperty decorated, "Patient.notAnElement",
			"fhirType", undefined
		assertChildCount decorated, "Patient.notAnElement", 2

	it "should decorate arrays that should be single values", ->
		decorated = decorate
			resourceType: "Patient"
			active: [true, true]

		assertProperty decorated, "Patient.active",
			"fhirType", undefined

	it "should decorate single values that should be arrays", ->
		decorated = decorate
			resourceType: "Patient"
			name: {given: "bob"}

		assertProperty decorated, "Patient.given",
			"fhirType", undefined

	it "should decorate nested referenced elements", ->
		decorated = decorate
			resourceType: "Questionnaire"
			group:
				group: [
					group: [
						group: [text: "test", text: "Test"]
					]
				]
		assert.equal decorated.children[1].children[0].children[0].schemaPath, 
			"Questionnaire.group"



###

describe "schema utils: primitive type extensions", ->

	it "should decorate primitive type extensions and ids", ->
		decorated = decorate
			resourceType: "Patient"
			birthDate: "1970-03-30"
			_birthDate:
				id: "314159"
				extension : [
					url : "http://example.org/fhir/StructureDefinition/text"
					valueString : "Easter 1970"
				]

	it "should decorate primitive types with arrays", ->
		decorated = decorate
			resourceType: "Coding"
			code: [ "", "nz" ]
			"_code": [
				null
				extension: [
					url: "http://hl7.org/fhir/StructureDefinition/display"
					valueString : "New Zealand a.k.a Kiwiland"
				]
			]
###

describe "schema utils: pretty print name", ->

	it "should handle multitype elements", ->
		schemaPath = "Patient.deceased[x]".split(".")
		fhirType = "boolean"
		displayName = SchemaUtils.buildDisplayName(schemaPath, fhirType)
		assert.equal displayName, "Deceased (boolean)"

	# Removed this feature since seems unnecessary
	# it "should handle camel case names", ->
	# 	schemaPath = "Patient.birthDate".split(".")
	# 	fhirType = "date"
	# 	displayName = SchemaUtils.buildDisplayName(schemaPath, fhirType)
	# 	assert.equal displayName, "Birth Date"

describe "schema utils: get child elements", ->

	it "should get children from a domain resource", ->
		schemaPath = "Patient"		
		children = SchemaUtils.getElementChildren(profiles, schemaPath)
		assert.equal getChildBySchemaPath(children, "Patient.language").length, 1
		assert.equal children.length, 27

	it "should get children from a backbone element", ->
		schemaPath = "Patient.animal"
		children = SchemaUtils.getElementChildren(profiles, schemaPath)
		assert.equal getChildBySchemaPath(children, "Patient.animal.species").length, 1
		assert.equal children.length, 6

	it "should get children from a complex type", ->
		schemaPath = "HumanName"
		children = SchemaUtils.getElementChildren(profiles, schemaPath)
		assert.equal getChildBySchemaPath(children, "HumanName.use").length, 1
		assert.equal children.length, 9

	it "should create permutations of multi-type values", ->
		schemaPath = "Patient"		
		children = SchemaUtils.getElementChildren(profiles, schemaPath)
		mtChildren = getChildBySchemaPath(children, "Patient.deceased[x]")
		assert.equal mtChildren.length, 2
		assert.equal mtChildren[0].name, "deceasedBoolean"

	it "should get referenced elements", ->
		schemaPath = "Questionnaire.group.question"
		children = SchemaUtils.getElementChildren(profiles, schemaPath)
		assert.equal getChildBySchemaPath(children, "Questionnaire.group.question.group").length, 1


describe "schema utils: create child", ->

	it "should create a value element", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.gender", "code"
		assert.equal child.name, "gender"
		assert.equal (child.children||[]).length, 0

	it "should create a value array with a single value", ->
		child = SchemaUtils.buildChildNode profiles, "object", "HumanName.given", "string"
		assert.equal child.name, "given"
		assert.equal child.nodeType, "valueArray"
		assert.equal child.children.length, 1
		assert.equal child.children[0].name, "given"
		assert.equal child.children[0].nodeType, "value"

	it "should create a multi-type element", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.deceased[x]", "boolean"
		assert.equal child.name, "deceasedBoolean"
		assert.equal child.displayName, "Deceased (boolean)"
		assert.equal (child.children||[]).length, 0

	it "should create a object element", ->
		child = SchemaUtils.buildChildNode profiles, "object", "HumanName.period", "Period"
		assert.equal child.name, "period"
		assert.equal child.nodeType, "object"
		assert.equal child.children.length, 0

	it "should create an object array with a single value", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.name", "HumanName"
		assert.equal child.fhirType, "HumanName"
		assert.equal child.nodeType, "objectArray"		
		assert.equal child.children.length, 1
		assert.equal child.children[0].fhirType, "HumanName"
		assert.equal child.children[0].nodeType, "arrayObject"

	it "should add an object to an array", ->
		child = SchemaUtils.buildChildNode profiles, "objectArray", "HumanName", "HumanName"
		assert.equal child.name, "HumanName"
		assert.equal child.nodeType, "arrayObject"
		assert.equal child.children.length, 0

	it "should create a nested backbone element", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.animal", "BackboneElement"
		assert.equal child.fhirType, "BackboneElement"
		assert.equal child.nodeType, "object"

	it "should create a nested backbone array with a single element", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.communication", "BackboneElement"
		assert.equal child.fhirType, "BackboneElement"
		assert.equal child.nodeType, "objectArray"
		assert.equal child.children.length, 1
		assert.equal child.children[0].schemaPath, "Patient.communication"
		assert.equal child.children[0].nodeType, "arrayObject"

	it "should add an object to a backbone array", ->
		child = SchemaUtils.buildChildNode profiles, "objectArray", "Patient.communication", "BackboneElement"
		assert.equal child.name, "communication"
		assert.equal child.fhirType, "BackboneElement"
		assert.equal child.nodeType, "arrayObject"

	it "should include required values in children", ->
		child = SchemaUtils.buildChildNode profiles, "object", "Patient.communication", "BackboneElement"
		# console.log JSON.stringify child, null, "  "
		comm = child.children[0]
		assert.equal comm.children.length, 1
		assert.equal comm.children[0].name, "language"






























