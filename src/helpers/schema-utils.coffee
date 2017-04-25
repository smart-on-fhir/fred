validator = require "./primitive-validator"
uuid = require "node-uuid"

#TODO: break up this module

nextId = 0

isComplexType = (fhirType) ->
	fhirType and
		fhirType[0] is fhirType[0].toUpperCase()

isInfrastructureType = (fhirType) ->
	fhirType in ["DomainResource", "Element", "BackboneElement"]

unsupportedElements = []

module.exports =
	
	toFhir: (decorated, validate) ->
		errCount = 0
		# console.log JSON.stringify decorated, null, "  "
		_walkNode = (node, parent={}) ->
			for child in node.children
				value = if child.nodeType in ["object", "arrayObject"]
					_walkNode child, {}
				else if child.nodeType in ["valueArray", "objectArray"]
					_walkNode child, []
				else
					if validate and child?.ui?.validationErr
						err = child?.ui?.validationErr
					else if validate and child.fhirType
						err = validator.isValid(child.fhirType, child.value, true)
					
					if err then errCount++
					child.value

				if parent instanceof Array
					parent.push value
				else
					parent[child.name] = value

			return parent

		fhir = _walkNode(decorated)
		if validate
			[fhir, errCount]
		else
			fhir


	# getAllowedReferences: (schemaPath) ->

	getElementChildren: (profiles, schemaPath, excludePaths=[]) ->
		_buildChild = (name, schema, typeCode) =>
			schemaPath: schema.path
			name: name
			displayName: @buildDisplayName(schema.path.split("."), typeCode)
			index: schema.index
			isRequired: schema.min >=1
			fhirType: typeCode
			short: schema.short
			range: [schema.min, schema.max]
			nodeType: if isComplexType(typeCode)
				if schema.max isnt "1" then "objectArray" else "object"
			else
				if schema.max isnt "1" then "valueArray" else "value"

		_buildMultiTypePermutations = (schema) ->
			permutations = []
			for type in schema.type
				capType = type.code[0].toUpperCase() + type.code.slice(1)
				name = schema.path.split(".").pop().replace("[x]", capType)
				permutations.push _buildChild(name, schema, type.code)
			return permutations

		_isMultiType = (schemaPath) ->
			path.indexOf("[x]") > -1

		children = []
		schemaRoot = schemaPath.split(".").shift()
		level = schemaPath.split(".").length

		for path, schema of (profiles[schemaRoot] || {})

			continue if path in excludePaths or
				path.indexOf(schemaPath) is -1 or
				path.split(".").length isnt level+1

			if schema?.nameReference
				schemaPath = schemaPath.split(".").shift() + "." + schema.nameReference
	
			if _isMultiType(path)
				children = children.concat _buildMultiTypePermutations(schema)
			else
				name = schema.path.split(".").pop()
				if name not in unsupportedElements
					type = schema?.type?[0]?.code || "BackboneElement"
					children.push _buildChild(name, schema, type)

		children = children.sort (a, b) -> a.index - b.index

	buildChildNode: (profiles, parentNodeType, schemaPath, fhirType) ->

		_addRequiredChildren = (parentNodeType, schemaPath, fhirType) =>

			if isComplexType(fhirType) and !isInfrastructureType(fhirType)
				schemaPath = fhirType

			children = @getElementChildren(profiles, schemaPath)

			reqChildren = []
			for child in children when child.isRequired
				reqChildren.push @buildChildNode profiles, parentNodeType, child.schemaPath, child.fhirType
			return reqChildren


		schemaPath = schemaPath.split(".")
		name = schemaPath[schemaPath.length-1]
		schema = profiles[schemaPath[0]]?[schemaPath.join(".")]

		if schema?.nameReference
				schemaPath = [schemaPath[0], schema.nameReference]

		if name.indexOf("[x]") > -1
			capType = fhirType[0].toUpperCase() + fhirType.slice(1)
			name = schema.path.split(".").pop().replace("[x]", capType)

		if schema.max isnt "1" and parentNodeType not in ["valueArray", "objectArray"]
			id: nextId++, name: name, index: schema.index
			schemaPath: schemaPath.join("."), fhirType: fhirType
			displayName: @buildDisplayName(schemaPath, fhirType)
			nodeType: if isComplexType(fhirType) then "objectArray" else "valueArray"
			short: schema.short
			nodeCreator: "user"
			isRequired: schema.min >=1
			range: [schema.min, schema.max]
			children:  if isComplexType(fhirType)
				[@buildChildNode profiles, "objectArray", schemaPath.join("."), fhirType]
			else
				[@buildChildNode profiles, "valueArray", schemaPath.join("."), fhirType]

		else
			result =
				id: nextId++, name: name, index: schema.index
				schemaPath: schemaPath.join("."), fhirType: fhirType
				displayName: @buildDisplayName(schemaPath, fhirType)
				isRequired: schema.min >=1
				short: schema.short
				nodeCreator: "user"
				value: if fhirType is "boolean" then true else null
				range: [schema.min, schema.max]
				binding: schema?.binding
				nodeType: if isComplexType(fhirType) and parentNodeType is "objectArray"
					"arrayObject"
				else if isComplexType(fhirType)
					"object"
				else
					"value"
			if isComplexType(fhirType)
				result.children = _addRequiredChildren result.nodeType,
					result.schemaPath, result.fhirType

			return result

	buildDisplayName: (schemaPath, fhirType) ->
		_fixCamelCase = (text, lowerCase) ->
			#function has an issue with consecutive capital letters (eg. ID)
			#and not convinced splitting camelcase words has value
			#so bypassing for now and just capitalizing first letter
			unless lowerCase
				text = text[0].toUpperCase() + text.slice(1)
			return text

		name = schemaPath[schemaPath.length-1]
		if name.indexOf("[x]") > -1
			_fixCamelCase(name.replace(/\[x\]/,"")) +
				" (" + _fixCamelCase(fhirType, true) + ")"
		else
			_fixCamelCase(name)

	isResource: (profiles, data) ->
		if data.resourceType and
			profiles[data.resourceType]
				return true

	decorateFhirData: (profiles, data) ->
		nextId = 0

		_walkNode = (dataNode, schemaPath, level=0, inArray) =>
			#root node
			if resourceType = dataNode.resourceType
				schemaPath = [resourceType]

			name = schemaPath[schemaPath.length-1]
			displayName = @buildDisplayName(schemaPath, null)
			schema = profiles[schemaPath[0]]?[schemaPath.join(".")]
			fhirType = schema?.type?[0]?.code

			if isInfrastructureType(fhirType) and schemaPath.length is 1
				fhirType = schemaPath[0]

			#contentReference and nameReference support
			if schema?.refSchema
				schemaPath = schema.refSchema.split(".")
				refSchema = profiles[schemaPath[0]]?[schemaPath.join(".")]
				fhirType = refSchema?.type?[0]?.code

			#is it a multi-type?
			if !fhirType
				nameParts = schemaPath[schemaPath.length-1].split(/(?=[A-Z])/)
				testSchemaPath = schemaPath.slice(0,schemaPath.length-1).join(".") + "."
				for namePart, i in nameParts
					testSchemaPath += "#{namePart}"
					if testSchema = profiles[schemaPath[0]]?["#{testSchemaPath}[x]"]
						schema = testSchema
						schemaPath = testSchema.path.split(".")
						fhirType = nameParts.slice(i+1).join("")
						#allow for complex type multi-types
						unless profiles[fhirType]
							fhirType = fhirType[0].toLowerCase() + fhirType.slice(1)
						displayName = @buildDisplayName(schemaPath, fhirType)

			decorated =
				id: nextId++, index: schema?.index || 0
				name: name, nodeType: "value", displayName: displayName
				schemaPath: schemaPath.join("."), fhirType: fhirType, level: level
				short: schema?.short, isRequired: schema?.min and schema.min >=1
				binding: schema?.binding
			

			if schema?.min != undefined 
				decorated.range = [schema?.min, schema?.max]

			#hide resourceType item
			if name == "resourceType"
				decorated.hidden = true

			#restart schema for complex types
			if isComplexType(fhirType) and !isInfrastructureType(fhirType)
				schemaPath = [fhirType]

			#this is a little sloppy, but simplifies blob rendering
			if fhirType is "Attachment" and dataNode.contentType and dataNode.data
				decorated.contentType = dataNode.contentType

			if dataNode instanceof Array and decorated.range and decorated.range[1] != "1"
				decorated.children = (
					_walkNode v, schemaPath, level+1, true for v, i in dataNode
				)
				decorated.nodeType = if fhirType and isComplexType(fhirType)
					"objectArray"
				#unknown object arrays
				else if !fhirType and typeof dataNode?[0] is "object"
					"objectArray"
				else
					"valueArray"

			else if typeof dataNode is "object" and 
				dataNode not instanceof Array and
				dataNode not instanceof Date
					decorated.nodeType = if schema and schema.max isnt "1" then "arrayObject" else "object"
					decorated.children = (
						_walkNode v, schemaPath.concat(k), level+1 for k, v of dataNode
					)
					decorated.children = decorated.children.sort (a, b) -> a.index - b.index

			else
				#some servers return decimals as numbers instead of strings
				#which, of course, don't validate.
				#This is very hacky - and arbitrarily sets precision
				#need a better approach.
				if fhirType is "decimal" and dataNode isnt ""
					dataNode = parseFloat(dataNode).toString()
					if dataNode.indexOf(".") is -1
						dataNode += ".0"

				decorated.value = dataNode

				#check if value has a cardinality of > 1 and isn't in an array
				if decorated.range?[1] && decorated.range[1] != "1" && !inArray
					decorated.fhirType = null

				#check if value has a cardinality of 1 and is in an array
				if dataNode instanceof Array && decorated.range?[1] == "1"
					decorated.fhirType = null

				if fhirType and error = validator.isValid(fhirType, dataNode)
					decorated.ui = {validationErr: error, status: "editing"}

			return decorated


		# console.log JSON.stringify _walkNode(data), null, "  "
		return _walkNode(data)
