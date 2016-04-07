State = require "./state"
SchemaUtils = require "./helpers/schema-utils"
BundleUtils = require "./helpers/bundle-utils"

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

getParentById = (id) ->
	_walkNode = (node) ->
		return unless node.children
		for child, i in node.children
			if child.id is id
				return [node, i]
			else if child.children
				if result = _walkNode(child)
					return result 
	_walkNode(State.get().resource)


State.on "load_profiles", (profilePath, initialResourcePath, isRemote) ->
	State.trigger "set_ui", "loading"
	
	onLoadSuccess = (json) ->
		State.get().set {profiles: json}
		if initialResourcePath
			State.trigger "load_url_resource", initialResourcePath
		else if !isRemote
			State.trigger "set_ui", "ready"

	onLoadError = (xhr, status) ->
		State.trigger set_ui, "profile_error"

	$.ajax 
		url: profilePath
		dataType: "json"
		success: onLoadSuccess
		error: onLoadError
			
State.on "load_url_resource", (resourcePath) ->
	state = State.get()
	state.ui.set {status: "loading", openMode: state.ui.openMode}
	$.ajax 
		url: resourcePath
		dataType: "json"
		success: (json) ->
			State.trigger "load_json_resource", json
		error: (xhr, status) ->
			State.get().ui.set {status: "load_error"}

checkBundle = (json) ->
	json.resourceType is "Bundle" and json.entry

decorateResource = (json, profiles) ->
	return unless SchemaUtils.isResource(profiles, json)
	SchemaUtils.decorateFhirData(profiles, json)

openResource = (json) ->
	state = State.get()

	if decorated = decorateResource(json, state.profiles)
		state.set {resource: decorated, bundle: null}
		return true

openBundle = (json) ->
	state = State.get()
	resources = BundleUtils.parseBundle(json)

	if decorated = decorateResource(resources[0], state.profiles)
		state.pivot()
			.set("bundle", {resources: resources, pos: 0})
			.set({resource: decorated})
		return true

bundleInsert = (json, isBundle) ->
	state = State.get()

	#stop if errors
	[resource, errCount] = 
		SchemaUtils.toFhir state.resource, true
	if errCount isnt 0 
		return state.ui.set("status", "validation_error")
	else
		state.bundle.resources.splice(state.bundle.pos, 1, resource).now()
		state = State.get()

	resources = if isBundle
		resources = SchemaUtils.parseBundle(json)
	else if json.id
		[json]
	else
		nextId = BundleUtils.findNextId(state.bundle.resources)
		json.id = BundleUtils.buildFredId(nextId)
		[json]

	if decorated = decorateResource(resources[0], state.profiles)
		state.pivot()
			.set("resource", decorated)
			.bundle.resources.splice(state.bundle.pos+1, 0, resources...)
			.bundle.set("pos", state.bundle.pos+1)
		return true

replaceContained = (json) ->
	state = State.get()
	if decorated = decorateResource(json, state.profiles)		
		[parent, pos] = getParentById(state.ui.replaceId)
		parent.children.splice(pos, 1, decorated)
		return true

isBundleAndRootId = (node, parent) ->
	node.fhirType is "id" and State.get().bundle and
		parent.level is 0

State.on "load_json_resource", (json) =>
	openMode = State.get().ui.openMode
	isBundle = checkBundle(json)

	success = if openMode is "insert"
		bundleInsert(json, isBundle)
	else if openMode is "contained"
		replaceContained(json)
	else if isBundle
		openBundle(json)
	else
		openResource(json)

	status = if success then "ready" else "load_error"
	State.get().set "ui", {status: status}

State.on "set_bundle_pos", (newPos) ->
	state = State.get()
	
	#stop if errors
	[resource, errCount] = 
		SchemaUtils.toFhir state.resource, true
	if errCount isnt 0 
		return state.ui.set("status", "validation_error")

	unless decorated = decorateResource(state.bundle.resources[newPos], state.profiles)
		return State.trigger "set_ui", "load_error"
	
	state.pivot()
		#splice in any changes
		.set("resource", decorated)
		.bundle.resources.splice(state.bundle.pos, 1, resource)
		.bundle.set("pos", newPos)
		.ui.set(status: "ready")


State.on "remove_from_bundle", ->
	state = State.get()
	pos = state.bundle.pos
	newPos = pos+1
	if newPos is state.bundle.resources.length
		pos = newPos = state.bundle.pos-1

	unless decorated = decorateResource(state.bundle.resources[newPos], state.profiles)
		return State.trigger "set_ui", "load_error"
	
	state.pivot()
		.set("resource", decorated)
		.bundle.resources.splice(state.bundle.pos, 1)
		.bundle.set("pos", pos)

State.on "clone_resource", ->
	state = State.get()

	#stop if errors
	[resource, errCount] = 
		SchemaUtils.toFhir state.resource, true
	if errCount isnt 0 
		return state.ui.set("status", "validation_error")

	resource.id = null
	bundleInsert(resource)

State.on "show_open_contained", (node) ->
	State.get().ui.pivot()
		.set("status", "open")
		.set("openMode", "contained")
		.set("replaceId", node.id)

State.on "show_open_insert", ->
	State.get().ui.pivot()
		.set("status", "open")
		.set("openMode", "insert")

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
		.ui.set("status", "editing")
		.ui.set("prevState", node)

getResourceType = (node) ->
	for child in node.children
		if child.name is "resourceType"
			return child.value

showReferenceWarning = (node, parent, fredId) ->
	prevId = node.ui.prevState.value
	currentId = fredId || node.value
	resourceType = getResourceType(parent)
	prevRef = "#{resourceType}/#{prevId}"
	newRef = "#{resourceType}/#{currentId}"
	changeCount = 
		BundleUtils.countRefs State.get().bundle.resources, prevRef
	if changeCount > 0
		State.get().ui.pivot()
			.set(status: "ref_warning") 
			.set(count: changeCount) 
			.set(update: [{from: prevRef, to: newRef }])

State.on "update_refs", (changes) ->
	resources = 
		BundleUtils.fixAllRefs(State.get().bundle.resources, changes)

	State.get().bundle.set("resources", resources)
	State.trigger "set_ui", "ready"

State.on "end_edit", (node, parent) ->
	if isBundleAndRootId(node, parent) and 
		node.value isnt node.ui.prevState.value
			showReferenceWarning(node, parent)

	node.ui.reset {status: "ready"}

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

	#don't allow deletion of root level id in bundled resource
	if isBundleAndRootId(node, parent)
		nextId = BundleUtils.findNextId(State.get().bundle.resources)
		fredId = BundleUtils.buildFredId(nextId)
		node.pivot()
			.set(value: fredId)
			.ui.set(status: "ready")

		showReferenceWarning(node, parent, fredId)

	else if index isnt null
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















