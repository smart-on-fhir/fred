React = require "react"
ValueDisplay = require "./value-display"
ValueEditor = require "./value-editor"

class ValueNode extends React.Component

	displayName: "ValueNode"

	shouldComponentUpdate: (nextProps) ->
		nextProps.node isnt @props.node

	componentWillMount: ->
		if @props.node.value in [null, undefined, ""] and
			@props.node?.ui?.status isnt "editing"
				@props.onEditStart()

	renderUnknown: ->
		content = if @props.node.value
			<ValueDisplay node={@props.node} parent={@props.parent} />
		else
			<span>Unknown Elements</span>

		<div className="fhir-data-element fhir-element-unknown row">
			<div className="col-sm-3 fhir-data-title">
				{@props.node.displayName}:
			</div>
			<div className="col-sm-9 fhir-data-content">
				{content}
			</div>
		</div>

	renderXhtmlEditing: ->
		preview =
			<div className="col-sm-9 col-sm-offset-3 fhir-data-content" style={marginTop: "10px"}>
				<ValueDisplay 
					node={@props.node} 
					parent={@props.parent}
				/>
			</div>

		@renderEditing(preview)

	renderEditing: (preview) ->
		required = if @props.node.isRequired then "*"

		<div className="fhir-data-element row">
			<div className="col-sm-3 fhir-data-title" title={@props.node.short}>
				{@props.node.displayName}{required} <span className="fhir-data-type">({@props.node.fhirType})</span>:
			</div>
			<div className="col-sm-9 fhir-data-content">
				<div className="fhir-short-desc">{@props.node.short}</div>
				<ValueEditor
					hasFocus={true}
					node={@props.node}
					parent={@props.parent}
					required={@props.node.isRequired}
					onEditCommit={@props.onEditCommit}
					onNodeDelete={@props.onNodeDelete}
					onEditCancel={@props.onEditCancel}
				/>
			</div>
			{preview}
		</div>

	renderDisplay: ->
		required = if @props.node.isRequired then "*"

		<div className="fhir-data-element row" onClick={@props.onEditStart} >
			<div className="col-sm-3 fhir-data-title" title={@props.node.short}>
				{@props.node.displayName}{required}:
			</div>
			<div className="col-sm-9 fhir-data-content">
				<ValueDisplay 
					node={@props.node} 
					parent={@props.parent}
				/>
			</div>
		</div>


	renderPreview: ->
		<div>preview</div>

	render: ->
		isEditing = @props.node?.ui?.status is "editing"
		#don't show hidden elements
		if @props.node.hidden then return null
		
		if !@props.node.fhirType
			@renderUnknown()
		else if isEditing and @props.node.fhirType is "xhtml"
			@renderXhtmlEditing()
		else if isEditing
			@renderEditing()
		else
			@renderDisplay()

module.exports = ValueNode