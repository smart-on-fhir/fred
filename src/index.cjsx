React    = require "react"
ReactDOM = require "react-dom"
State = require "./reactions"
SchemaUtils = require "./schema-utils"

Navbar = require "./navbar"
BundleBar = require "./bundle-bar"

DomainResource = require "./domain-resource/"

OpenDialog = require "./open-dialog"
ExportDialog = require "./export-dialog"

{Tabs, Tab} = require "react-bootstrap"

class RootComponent extends React.Component

	constructor: ->
		@state = {activeTab: "first"}

	componentWillMount: ->
		qs = window.location.search.substr(1)
		resourceMatches = qs.match /resource=([^&]+)/
		if resourceMatches?[1]
			resourcePath = decodeURIComponent(resourceMatches[1])
			State.trigger("load_url_resource", resourcePath)
		else
			State.trigger("set_ui", "open")

		@isRemote = /remote=1/.test(qs)
		State.trigger("load_profiles")

	componentDidMount: ->
		State.on "update", => @forceUpdate()

	handleOpen: ->
		State.trigger("set_ui", "open")

	render: ->
		state = State.get()

		if state.bundle
			bundleBar = <BundleBar bundle={state.bundle} />
		
		resourceContent = if state.ui.status is "loading"
			<div className="spinner"><img src="./img/ajax-loader.gif" /></div>
		else if state.resource
			<DomainResource node={state.resource} /> 
		else if !state.bundle
			<div className="row" style={marginTop: "20px"}><div className="col-xs-offset-4 col-xs-4">
				<button className="btn btn-primary btn-block" onClick={@handleOpen.bind(@)}>
					Open Resource
				</button>
			</div></div>

		error = if state.ui.status is "load_error"
			<div className="alert alert-danger">An error occured loading the resource.</div>
		else if state.ui.status is "validation_error"
			<div className="alert alert-danger">Please fix errors in resource before continuing.</div>

		<div>
			<Navbar isRemote={@isRemote} hasResource={if state.resource then true} />
			<div className="container" style={marginTop: "50px", marginBottom: "50px"}>
				{bundleBar}
				{error}
				{resourceContent}
			</div>
			<OpenDialog show={state.ui.status is "open"} />
			<ExportDialog show={state.ui.status is "export"}
				bundle={state.bundle}
				resource={state.resource}
			/>
		</div>


ReactDOM.render <RootComponent />, document.getElementById("content")