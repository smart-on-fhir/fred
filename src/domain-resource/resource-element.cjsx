React    = require "react"
ReactDOM = require "react-dom"

State = require "../state"
validator = require "../helpers/primitive-validator"

ValueEditor = require "./value-editor"
ValueDisplay = require "./value-display"
ValueNode = require "./value-node"
ValueArrayNode = require "./value-array-node"
ElementMenu = require "./element-menu"

class ResourceElement extends React.Component

	displayName: "ResourceElement"

	isValid: (node) ->
		#this is hacky - need to find a better place for pre-commit validation
		for editNode in node.children || [node]
			return false if node.ui?.validationErr
			if message = validator.isValid(editNode.fhirType, editNode.value, true)
				State.trigger("value_change", editNode, editNode.value, message)
				return false

		return true

	shouldComponentUpdate: (nextProps) ->
		nextProps.node isnt @props.node

	componentDidMount: ->
		if @refs.complexElement and @props.node?.nodeCreator is "user"
			domNode = ReactDOM.findDOMNode @refs.complexElement
			domNode.scrollIntoView(true)
			#account for fixed header
			scrollY = window.scrollY
			if scrollY
				window.scroll(0, scrollY - 60)

	handleEditStart: (e) ->
		State.trigger("start_edit", @props.node)
		e.preventDefault() if e

	handleEditCancel: (e) ->
		#don't allow cancel if no previous value
		if @props.node?.ui?.prevState?.value in [null, undefined, ""]
			return
		State.trigger("cancel_edit", @props.node)
		e.preventDefault() if e

	handleEditCommit:  (e) ->
		return unless @isValid(@props.node)
		State.trigger("end_edit", @props.node, @props.parent)
		e.preventDefault() if e

	handleNodeDelete: (e) ->
		State.trigger("delete_node", @props.node, @props.parent)
		e.preventDefault() if e

	handleAddContained: (e) ->
		State.trigger("show_open_contained", @props.node)
		e.preventDefault() if e

	handleObjectMenu: (e) ->
		return if @props.node?.ui?.status is "menu"
		State.trigger("show_object_menu", @props.node, @props.parent)
		e.preventDefault() if e

	renderChildren: ->
		children = []
		for child in @props.node.children
			children.push <ResourceElement 
				key={child.id} node={child} 
				parent={@props.node}
			/>		
		return children

	render: ->

		if @props.node.nodeType is "value" or !@props.node.fhirType
			
				<ValueNode 
					node={@props.node} 
					parent={@props.parent} 
					onEditStart={@handleEditStart.bind(@)}
					onEditCommit={@handleEditCommit.bind(@)}
					onEditCancel={@handleEditCancel.bind(@)}
					onNodeDelete={@handleNodeDelete.bind(@)}
				/>


		else if @props.node.nodeType is "valueArray"
				
				<ValueArrayNode 
					node={@props.node} 
					parent={@props.parent} 
					onEditStart={@handleEditStart.bind(@)}
					onEditCommit={@handleEditCommit.bind(@)}
					onEditCancel={@handleEditCancel.bind(@)}
					onNodeDelete={@handleNodeDelete.bind(@)}
				/>

		else if @props.node.nodeType is "objectArray"

			<div className="fhir-data-element row" ref="complexElement">
				<div className="col-sm-12">
					{@renderChildren()}
				</div>
			</div>

		#handle contained resources
		else if @props.node.fhirType is "Resource"

				<div className="fhir-array-complex-wrap" ref="complexElement">
					<ElementMenu node={@props.node} 
						parent={@props.parent} display="heading" />
					<div className="fhir-array-complex text-center">
						<button className="btn btn-primary" onClick={@handleAddContained.bind(@)}>
							Choose Resource
						</button>
					</div>
				</div>


		else if @props.node.nodeType is "arrayObject"

				<div className="fhir-array-complex-wrap" ref="complexElement">
					<ElementMenu node={@props.node} 
						parent={@props.parent} display="heading" />
					<div className="fhir-array-complex">
						{@renderChildren()}
					</div>
				</div>

		else if @props.node.nodeType is "object"

			<div className="fhir-data-element row" ref="complexElement">
				<div className="col-sm-3">
					<ElementMenu node={@props.node} 
						parent={@props.parent} display="inline" 
					/>
				</div>
				<div className="col-sm-9">
					{@renderChildren()}
				</div>
			</div>




module.exports = ResourceElement