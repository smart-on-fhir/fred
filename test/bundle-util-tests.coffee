assert   = require "assert"

BundleUtils = require "../src/helpers/bundle-utils.coffee"

describe "bundle utils: resource management", ->
	beforeEach ->
		@resources = [
			resourceType: "Patient"
			id: "FRED-1"
		,
			resourceType: "Observation"
			id: "123"
			subject: {reference: "Patient/FRED-1"}
		,
			resourceType: "Observation"
			id: "124"
			subject: {reference: "Patient/FRED-1"}
		]

	it "should find all references to a resource", ->
		count = BundleUtils.countRefs @resources, "Patient/FRED-1" 
		assert.equal count, 2


describe "bundle utils: bundle parsing", ->
	beforeEach ->
 		@bundle =
			resourceType: "Bundle"
			type: "batch"
			entry:[
				request: {method: "PUT"}
				fullUrl: "urn:uuid:d3d2416a-abec-4991-ba1c-d3c76badc7c7"
				resource:
					resourceType: "Patient"
			,
				request: {method: "PUT", url:"Observation/123"}
				fullUrl: "Observation/123"
				resource:
					resourceType: "Observation"
					id: "123"
					subject: {reference: "urn:uuid:d3d2416a-abec-4991-ba1c-d3c76badc7c7"}
			]


	it "should add a fred id if fullUrl is uuid", ->
		resources = BundleUtils.parseBundle(@bundle)
		assert.equal resources[0].id, "FRED-1"

	it "should add fred id if resource doesn't have an id", ->
		delete @bundle.entry[1].resource.id
		resources = BundleUtils.parseBundle(@bundle)
		assert.equal resources[1].id, "FRED-2"

	it "should begin numbering fred id from max id", ->
		delete @bundle.entry[1].resource.id
		@bundle.entry[0].resource.id = "FRED-4"
		@bundle.entry[0].fullUrl = null
		resources = BundleUtils.parseBundle(@bundle)
		assert.equal resources[1].id, "FRED-5"

	it "should not add a fred id if a valid id element exists", ->
		resources = BundleUtils.parseBundle(@bundle)
		assert.equal resources[1].id, "123"

	it "should add a fred id if clearInternalIds is set", ->
		resources = BundleUtils.parseBundle(@bundle, true)
		assert.equal resources[1].id, "FRED-2"

	it "should update references in bundle to fred id", ->
		resources = BundleUtils.parseBundle(@bundle)
		assert.equal resources[1].subject.reference, "Patient/FRED-1"


describe "bundle utils: bundle generation", ->
	beforeEach ->
		@resources = [
			resourceType: "Patient"
			id: "FRED-1"
		,
			resourceType: "Observation"
			id: "123"
			subject: {reference: "Patient/FRED-1"}
		]

	it "should generate uuid based fullUrls for resources with tempIds", ->
		bundle = BundleUtils.generateBundle(@resources)
		assert.equal bundle.entry[0].fullUrl.slice(0, 9), "urn:uuid:"

	it "should replace references to fred ids with generated uuids", ->
		bundle = BundleUtils.generateBundle(@resources)
		assert.equal bundle.entry[1].resource.subject.reference.slice(0, 9), "urn:uuid:"

	it "should generate relative fullUrls for resources with permanent ids", ->
		bundle = BundleUtils.generateBundle(@resources)
		assert.equal bundle.entry[1].fullUrl, "Observation/123"

	it "should generate uuid based fullUrls for resources without ids", ->
		delete @resources[1].id
		bundle = BundleUtils.generateBundle(@resources)
		assert.equal bundle.entry[1].resource.subject.reference.slice(0, 9), "urn:uuid:"
































