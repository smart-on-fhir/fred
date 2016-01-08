React    = require "react"
ReactDOM = require "react-dom"
State = require "../state"
validator = require "../primitive-validator"

class ValueEditor extends React.Component

	displayName: "ValueEditor"

	ESC_KEY: 27
	ENTER_KEY: 13
	TAB_KEY: 9

	shouldComponentUpdate: (nextProps) ->
		nextProps.node isnt @props.node

	componentDidMount: ->
		if @props.hasFocus and @refs.inputField
			domNode = @refs.inputField
			domNode.focus()
			if domNode.setSelectionRange
				domNode.setSelectionRange(domNode.value.length, domNode.value.length)

		if @props.node.fhirType is "xhtml"
			#remove blank lines
			if @props.node.value
				newValue = @props.node.value.replace(/^\s*[\r\n]/gm, "")
				State.trigger("value_change", @props.node, newValue)

	handleChange: (e) ->
		isInvalid = @isValid(@props.node.fhirType, e.target.value)
		State.trigger("value_change", @props.node, e.target.value, isInvalid)

	handleKeyDown: (e) ->
		if e.which is @ESC_KEY
			@props.onEditCancel(e)
		else if e.which is @ENTER_KEY and 
			e.target.type is "text"
				@props.onEditCommit(e)
		else if e.which is @TAB_KEY and
			@props.node.fhirType is "xhtml"
				#bug where selection will jump to end of string
				#http://searler.github.io/react.js/2014/04/11/React-controlled-text.html
				e.preventDefault()
				newValue = e.target.value.substring(0, e.target.selectionStart) + "\t" + 
					e.target.value.substring(e.target.selectionEnd)
				e.target.value = newValue
 
	isValid: (fhirType, value) ->
		validator.isValid(fhirType, value)

	renderString: (value) ->
		inputField = @buildTextInput (value||"").toString() 
		@wrapEditControls(inputField)
		
	renderLongString: (value) ->
		inputField = @buildTextAreaInput (value||"").toString() 
		@wrapEditControls(inputField)
	
	renderBoolean: (value) ->
		inputField = @buildDropdownInput(value)
		@wrapEditControls(inputField)

	buildDropdownInput: (value) ->
		<span>
			<select value={@props.node.value} 
				className="form-control input-sm" 
					onChange={@handleChange.bind(@)} 
					ref="inputField"
				>
				<option value={true}>Yes</option>
				<option value={false}>No</option>
			</select>
		</span>

	buildTextAreaInput: (value) ->
		if @props.node.fhirType is "xhtml"
			xhtmlClass = " fhir-xhtml-edit"

		<textarea 
			ref="inputField"
			className={"form-control input-sm" + (xhtmlClass||"")}
			onChange={@handleChange.bind(@)}
			onKeyDown={@handleKeyDown.bind(@)}
			value={value}
		/>

	buildTextInput: (value) ->
		<input 
			ref="inputField"
			className="form-control input-sm"
			value={value}
			onChange={@handleChange.bind(@)}
			onKeyDown={@handleKeyDown.bind(@)}
		/>

	buildCommitButton: ->
		commitButtonClassName = "btn btn-default btn-sm"
		if @props.node.value in [null, undefined, ""] or 
			@props?.node?.ui?.validationErr
				commitButtonClassName += " disabled"

		<button type="button" 
			className={commitButtonClassName} 
			onClick={@props.onEditCommit}
		>
			<span className="glyphicon glyphicon-ok"></span>
		</button>

	buildDeleteButton: (disabled) ->
		<button type="button" 
			className="btn btn-default btn-sm" 
			onClick={@props.onNodeDelete}
			disabled={disabled}
		>
			<span className="glyphicon glyphicon-trash"></span>
		</button>

	wrapEditControls: (inputField) ->
		groupClassName = "input-group"

		if validationErr = @props?.node?.ui?.validationErr
			groupClassName += " has-error"
			validationHint = <div className="help-block">{validationErr}</div>

		if @props.parent.nodeType is "valueArray"
			groupClassName += " fhir-value-array-input"

		unless @props.parent.nodeType is "valueArray"
			commitButton = @buildCommitButton()

		<div>
			<div className={groupClassName}>
				{inputField}
				<span className="input-group-btn">
					{commitButton}
					{@buildDeleteButton(@props.required)}
				</span>
			</div>
			<div className={if validationErr then "has-error"}>
				{validationHint}
			</div>
		</div>


	render: ->
		renderers = 
			decimal: @renderDecimal, boolean: @renderBoolean, xhtml: @renderLongString, 
			base64Binary: @renderLongString

		renderer = renderers[@props.node.fhirType || "string"] || @renderString
		value = @props.node.value
		renderer.call(@, value)

module.exports = ValueEditor





