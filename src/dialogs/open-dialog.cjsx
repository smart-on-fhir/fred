React = require "react"
ReactDOM = require "react-dom"
Modal = require("react-bootstrap").Modal
bsInput = require("react-bootstrap").Input
{Tabs, Tab}  = require("react-bootstrap")

State = require "../state"
SchemaUtils = require "../helpers/schema-utils"

class OpenDialog extends React.Component

	constructor: (props) ->
		super
		@state = 
			showSpinner: false,
			tab: "fhirText"
			fhirText: '{"resourceType": "Patient"}', fhirUrl: ""
			newResourceType: "Patient",
			newResourceBundle: false

	componentDidUpdate: (prevProps, prevState) ->
		return if @props.show is false or 
			(prevState.tab is @state.tab and
			prevProps.show is @props.show)

		window.setTimeout =>
			@refs[@state.tab].focus()
		, 100

	handleKeyDown: (e) ->
		if @state.tab is "text" and
			e.ctrlKey or e.metaKey
				@selectAll(@refs.fhirText)

	handleDrag: (action, e) ->
		e.preventDefault()
		if action is "over"
			@setState {drag: true}
		else if action is "leave"
			@setState {drag: false}
		else if action is "drop"
			if droppedFiles = e.dataTransfer?.files
				e.target.files = droppedFiles
				@handleFileSelected(e)

	selectAll: (domNode) ->
		return unless domNode
		domNode.focus()
		if domNode.selectionStart is domNode.selectionEnd and
			domNode.setSelectionRange
				domNode.setSelectionRange(0, domNode.value.length)

	handleClose: (e) ->
		@setState {showSpinner:false}
		State.trigger "set_ui", "ready"

	handleSelectFile: (e) ->
		@refs.fileReaderInput.click()

	handleFileSelected: (e) ->
		file = e?.target?.files?[0]
		return unless file
		reader = new FileReader()
		reader.onload = (e) => 
			@loadTextResource e.target.result
			@setState {showSpinner: false}
		reader.readAsText(file)
		@setState {showSpinner: true}

	loadTextResource: (data) ->
		try
			json = JSON.parse data
			State.trigger "load_json_resource", json
		catch e
			State.trigger "set_ui", "load_error"

	handleLoadText: (e) ->
		@loadTextResource @state.fhirText

	handleTextChange: (e) ->
		@setState {fhirText: e.target.value}

	handleLoadUrl: (e) ->
		return unless @state.fhirUrl.length > 2
		State.trigger "load_url_resource", @state.fhirUrl
		e.preventDefault()

	handleUrlChange: (e) ->
		@setState {fhirUrl: e.target.value}

	handleLoadNew: (e) ->
		e.preventDefault()
		json = {resourceType: @state.newResourceType}
		if @state.newResourceBundle
			json = {resourceType: "Bundle", entry: [{resource: json}]}
		State.trigger "load_json_resource", json

	handleNewTypeChange: (e) ->
		@setState {newResourceType: e.target.value}

	handleNewBundleChange: (e) ->
		@setState {newResourceBundle: !@state.newResourceBundle}

	handleTabChange: (key) ->
		@setState {tab: key}

	renderFileInput: ->
		dragClass = if @state.drag then " dropzone" else ""
		<div className={"row" + dragClass} 
			onDrop={@handleDrag.bind(@, "drop")} 
			onDragOver={@handleDrag.bind(@, "over")}
			onDragEnter={@handleDrag.bind(@, "enter")}
			onDragLeave={@handleDrag.bind(@, "leave")}
		>
			<div className="col-xs-10 col-xs-offset-1" style={marginTop:"20px"}>
				<p className="text-center">Choose (or drag and drop) a local JSON FHIR Resource or Bundle</p>
			</div>
			<div className="col-xs-4 col-xs-offset-4" style={marginTop:"20px", marginBottom:"10px"}>
				<button className="btn btn-primary btn-block"
					onClick={@handleSelectFile.bind(@)}
					ref="fhirFile"
				>
					Select File
				</button>
			</div>
			<input type="file" style={display:"none"} ref="fileReaderInput"
				onChange={@handleFileSelected.bind(@)} 
				accept=".json"/>
		</div>

	renderTextInput: ->
		<div className="row">
			<div className="col-xs-12">
				<p style={marginTop: "20px"}>Paste in a JSON FHIR Resource or Bundle:</p>
				<textarea ref="fhirText" className="form-control"
					style={height:"200px", marginTop:"10px", marginBottom:"10px"}
					onChange={@handleTextChange.bind(@)}
					value={@state.fhirText}
					onKeyDown={@handleKeyDown.bind(@)}
				/>
			</div>
			<div className="col-xs-4 col-xs-offset-4" style={marginBottom:"10px"}>
				<button className="btn btn-primary btn-block" 
					onClick={@handleLoadText.bind(@)} 
					disabled={@state.fhirText.length < 3}
				>
					Load JSON
				</button>
			</div>
		</div>

	renderUrlInput: ->
		<form onSubmit={@handleLoadUrl.bind(@)}>
		<div className="row">
			<div className="col-xs-12">
				<p style={marginTop: "20px"}>Enter the URL for a JSON FHIR Resource or Bundle:</p>
				<input ref="fhirUrl" className="form-control"
					style={marginTop:"10px", marginBottom:"10px"}
					onChange={@handleUrlChange.bind(@)}
					value={@state.fhirUrl}
				/>
			</div>
			<div className="col-xs-4 col-xs-offset-4" style={marginBottom:"10px"}>
				<button className="btn btn-primary btn-block" 
					onClick={@handleLoadUrl.bind(@)}
					disabled={@state.fhirUrl.length < 3}
				>
					Read JSON
				</button>
			</div>
		</div>
		</form>

	renderNewInput: ->
		resourceNames = []
		for k, v of State.get().profiles
			if v[k]?.type?[0]?.code is "DomainResource"
				resourceNames.push k
		resourceOptions = []
		for name in resourceNames.sort()
			resourceOptions.push <option value={name} key={name}>{name}</option>

		<form onSubmit={@handleLoadNew.bind(@)}>
		<div className="row">
			<div className="col-xs-12">
				<p style={marginTop: "20px"}>Choose a FHIR Resource Type:</p>
				<select ref="fhirNew" className="form-control"
					style={marginTop:"10px"}
					onChange={@handleNewTypeChange.bind(@)}
					value={@state.newResourceType}
				>{resourceOptions}</select>
			</div>
			{if !@props.openMode then @renderNewBundleOption()}
			<div className="col-xs-4 col-xs-offset-4" style={marginTop: "10px", marginBottom:"10px"}>
				<button className="btn btn-primary btn-block" 
					onClick={@handleLoadNew.bind(@)}
				>
					Create Resource
				</button>
			</div>
		</div>
		</form>

	renderNewBundleOption: ->
		<div className="col-xs-12 checkbox">
			<label>
				<input type="checkbox" 
					checked={@state.newResourceBundle} 
					onChange={@handleNewBundleChange.bind(@)}
				/>
				 Create in a Bundle
			</label>
		</div>

	renderTabs: ->
		<Tabs 
			activeKey={@state.tab} 
			animation={false}
			onSelect={@handleTabChange.bind(@)}
			onKeyDown={@handleKeyDown.bind(@)}
		>
			<Tab eventKey="fhirFile" title="Local File">
				{@renderFileInput()}
			</Tab>
			<Tab eventKey="fhirText" title="Paste JSON">
				{@renderTextInput()}
			</Tab>
			<Tab eventKey="fhirUrl" title="Website URL">
				{@renderUrlInput()}
			</Tab>
			<Tab eventKey="fhirNew" title="Blank Resource">
				{@renderNewInput()}
			</Tab>

		</Tabs>

	renderSpinner: ->
		<div className="spinner"><img src="./img/ajax-loader.gif" /></div>


	render: ->
		return null unless @props.show

		title = if @props.openMode is "insert_before" or @props.openMode is "insert_after"
			"Insert Resource"
		else
			"Open Resource"

		content = if @state.showSpinner
			@renderSpinner()
		else
			@renderTabs()

		<Modal show={true} onHide={@handleClose.bind(@)}>
			<Modal.Header closeButton>
				<Modal.Title>{title}</Modal.Title>
			</Modal.Header>
			<Modal.Body>
				{content}
			</Modal.Body>
		</Modal>




module.exports = OpenDialog