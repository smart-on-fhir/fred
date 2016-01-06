State = require "./state"
SchemaUtils = require "./schema-utils.coffee"
# parallel = require "osh-async-parallel"

canMoveNode = (node, parent) ->
	unless parent?.nodeType in ["objectArray", "valueArray"]
		return [false, false]
	index = parent.children.indexOf(node)
	[index>0, index<parent.children.length-1]

findParent = (targetNode) ->
	_walkNode = (node) ->
		return unless node.children
		for child, i in node.children
			if child is targetNode
				return [node, i]
			else if child.children
				if result = _walkNode(child)
					return result 
	_walkNode(State.get().resource)

getSplicePosition = (children, index) ->
	for child, i in children
		if child.index > index
			return i
	return children.length

getChildBySchemaPath = (node, schemaPath) ->
	for child in node.children
		return child if child.schemaPath is schemaPath

State.on "load_url_resource", (resourcePath, mode) ->
	State.get().ui.set {status: "loading"}
	$.ajax 
		url: resourcePath
		dataType: "json"
		success: (json) ->
			State.trigger "load_json_resource", json
		error: (xhr, status) ->
			State.get().ui.set {status: "load_error"}

isBundle = (json) ->
	json.resourceType is "Bundle" and 
		json.entry

State.on "load_json_resource", (json, mode) =>
	if isBundle(json)
		State.trigger("load_json_bundle", json, mode)
	else
		State.get().pivot()
			.set("rawResource", json)
			.set("bundle", null)
		State.trigger "resource_loaded"

State.on "load_json_bundle", (json) ->
	resources = (entry.resource for entry in json.entry)
	State.get().pivot()
		.set("rawResource", resources[0])
		.set("bundle", {resources: resources, pos: 0})
	if resources[0]
		State.trigger "resource_loaded"
	else
		State.get().ui.set "status", "ready"

State.on "set_bundle_pos", (newPos) ->
	state = State.get()
	#stop if errors
	[resource, errCount] = 
		SchemaUtils.toFhir state.resource, true
	if errCount isnt 0
		return state.ui.set("status", "validation_error")

	rawResource = 
		state.bundle.resources[newPos]
	state.pivot()
		#splice in any changes
		.bundle.resources.splice(state.bundle.pos, 1, resource)
		.bundle.set("pos", newPos)
		.ui.set("status", "loading")
		.set("rawResource", rawResource)

	State.trigger "resource_loaded"
	
State.on "load_profiles", ->
	$.ajax 
		url: "profiles.json"
		dataType: "json"
		success: (json) ->
			State.trigger "profiles_loaded", json
		error: (xhr, status) ->
			State.get().ui.set {status: "error"}

State.on "profiles_loaded", (json) ->
	State.get().set {profiles: json}
	State.trigger("resource_loaded")

State.on "resource_loaded", ->
	profiles = State.get().profiles
	rawResource = State.get().rawResource
	return unless profiles and rawResource
	unless SchemaUtils.isResource(profiles, rawResource)
		return State.get().ui.set(status: "load_error")
	decorated = SchemaUtils.decorateFhirData(profiles, rawResource)
	State.get()
		.set {resource: decorated}
		.set {"rawResource": null}
		.ui.set {status: "ready"}

State.on "set_ui", (status, params={}) ->
	State.get().ui.set {status: status, params: params}

State.on "value_update", (node, value) ->
	node.ui.reset {status: "ready"}

State.on "value_change", (node, value, validationErr, strictValidationErr) ->
	#in case there are pre-save errors
	State.get().ui.set {status: "ready"}

	if node.ui
		node.pivot()
			.set(value: value)
			.ui.set(validationErr: validationErr)
			.now()
	else
		node.pivot()
			.set(value: value)
			.set(ui: {})
			.ui.set(validationErr: validationErr)
			.now()

State.on "start_edit", (node) ->
	node.pivot()
		.set(ui: {})
		.ui.set(status: "editing")
		.ui.set(prevState: node)

State.on "end_edit", (node) ->
	node.ui.reset {status: "ready"}

# State.on "save_resource", ->
# 	resource = State.get().resource
# 	[fhir, errCount] = SchemaUtils.toFhir(resource, true)
# 	if errCount > 0
# 		State.get().ui.pivot()
# 			.set("status", "validation_error")
# 	else
# 		State.get().ui.pivot()
# 			.set("status", "done")
# 			.set("fhir", fhir)

State.on "cancel_edit", (node) ->
	if node.ui.validationErr
		State.get().ui.set "status", "ready"
	if node.ui.prevState
		node.reset(node.ui.prevState.toJS())

State.on "delete_node", (node, parent) ->

	if parent.nodeType is "objectArray" and
		parent.children.length is 1
			[targetNode, index] = findParent(parent)
	else
		targetNode = parent
		index = parent.children.indexOf(node)

	if index isnt null
		targetNode.children.splice(index, 1)



State.on "move_array_node", (node, parent, down) ->
	position = parent.children.indexOf(node)
	newPostion = if down then position+1 else position-1

	node = node.toJS()
	node.ui.status = "ready"
	parent.children
		.splice(position, 1)
		.splice(newPostion, 0, node)

State.on "show_object_menu", (node, parent) ->
	if node.nodeType isnt "objectArray"
		profiles = State.get().profiles
		usedElements = []
		for child in node.children 
			if !child.range or child.range[1] is "1" or child.nodeType is "valueArray" or (
				child.range[1] isnt "*" and parseInt(child.range[1]) < (child?.children?.length || 0)
			)
				usedElements.push child.schemaPath

		fhirType = if node.fhirType is "BackboneElement" then node.schemaPath else node.fhirType 
		unusedElements = SchemaUtils.getElementChildren(profiles, fhirType, usedElements)
	[canMoveUp, canMoveDown] = canMoveNode(node, parent)

	node.pivot()
		.set(ui: {})
		.ui.set(status: "menu")
		.ui.set(menu: {})
		.ui.menu.set(canMoveUp: canMoveUp)
		.ui.menu.set(canMoveDown: canMoveDown)
		.ui.menu.set(unusedElements: unusedElements)

State.on "add_array_value", (node) ->
	profiles = State.get().profiles
	newNode = SchemaUtils.buildChildNode(profiles, "valueArray", node.schemaPath, node.fhirType)
	newNode.ui = {status: "editing"}
	node.children.push newNode

State.on "add_array_object", (node) ->
	profiles = State.get().profiles
	newNode = SchemaUtils.buildChildNode(profiles, "objectArray", node.schemaPath, node.fhirType)
	node.children.push newNode	

State.on "add_object_element", (node, fhirElement) ->
	profiles = State.get().profiles

	if fhirElement.range and fhirElement.range[1] isnt "1" and
		child = getChildBySchemaPath(node, fhirElement.schemaPath)
			newNode = SchemaUtils.buildChildNode(profiles, "objectArray", child.schemaPath, child.fhirType)
			child.children.push newNode			
			return

	newNode = SchemaUtils.buildChildNode(profiles, node.nodeType, fhirElement.schemaPath, fhirElement.fhirType)
	if newNode.nodeType in ["value", "valueArray"]
		newNode.ui = {status: "editing"}
	position = getSplicePosition(node.children, newNode.index)
	node.children.splice(position, 0, newNode)

module.exports = State















