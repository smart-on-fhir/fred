React = require "react"
State = require "../state"
ValueDisplay = require "./value-display"
ValueEditor = require "./value-editor"

class ValueArrayNode extends React.Component

	displayName: "ValueArrayNode"

	shouldComponentUpdate: (nextProps) ->
		nextProps.node isnt @props.node

	handleItemAdd: (e) ->
		State.trigger("add_array_value", @props.node)
		e.preventDefault() if e

	handleItemDelete: (child, e) ->
		if @props.node.children.length is 1
			@props.onNodeDelete()
		else
			State.trigger("delete_node", child, @props.node)
		e.preventDefault()

	componentWillMount: ->
		if @props.node.children.length is 0 and
			@props.node?.ui?.status isnt "editing"
				@props.onEditStart()

	componentDidUpdate: ->
		#give 'em a first item
		if @props.node?.ui?.status is "editing" and 
			@props.node.children.length is 0
				@handleItemAdd()

	renderEditing: ->
		children = []
		for child, i in @props.node.children
			children.push <ValueEditor
				key={i}
				hasFocus={i == @props.node.children.length-1}
				node={child}
				parent={@props.node}
				onEditCommit={@props.onEditCommit}
				onNodeDelete={@handleItemDelete.bind(@, child)}
				onEditCancel={@props.onEditCancel}
				required={@props.node.isRequired and @props.node.children.length is 1}
			/>

		required = if @props.node.isRequired then "*"

		<div className="row fhir-data-element">
			<div className="col-sm-3 fhir-data-title">
				{@props.node.displayName} <span className="fhir-data-type">({@props.node.fhirType})</span>:
			</div>
			<div className="col-sm-9 fhir-data-content">
				<div className="fhir-short-desc">{@props.node.short}{required}</div>
				{children}
				<div className="btn-toolbar" role="group" style={marginTop: "6px"}>					
					<button type="button" className="btn btn-default btn-sm" onClick={@handleItemAdd.bind(@)}>
						<span className="glyphicon glyphicon-plus"></span>
					</button>
					<button type="button" className="btn btn-default btn-sm" onClick={@props.onEditCommit}>
						<span className="glyphicon glyphicon-ok"></span>
					</button>
				</div>
			</div>
		</div>


	renderDisplay: -> 

		required = if @props.node.isRequired then "*"

		children = []
		for child, i in @props.node.children
			children.push <ValueDisplay 
				key={i} node={child} parent={@props.node} /> 

		<div className="row fhir-data-element fhir-data-unknown" onClick={@props.onEditStart}>
			<div className="col-sm-3 fhir-data-title">
				{@props.node.displayName}{required}:
			</div>
			<div className="col-sm-9 fhir-data-content">
				{children}
			</div>
		</div>

	render: ->

		if @props.node?.ui?.status is "editing"
			@renderEditing()
		else
			@renderDisplay()




module.exports = ValueArrayNode