React    = require "react"
ReactDOM = require "react-dom"
State = require "./reactions"
SchemaUtils = require "./schema-utils"

Navbar = require "./navbar"
RemoteNavbar = require "./remote-navbar"
BundleBar = require "./bundle-bar"

DomainResource = require "./domain-resource/"

OpenDialog = require "./open-dialog"
ExportDialog = require "./export-dialog"

AppInfo = require "../package.json"

class RootComponent extends React.Component
	
	constructor: ->
		versionSegments = AppInfo.version.split(".")
		#only take the major and minor
		@appVersion = versionSegments.slice(0,versionSegments.length-1).join(".")
		super

	getQs: ->
		data = {}
		params = window.document.location.search?.substr(1).split("&")
		for param in params
			[k,v] = param.split("=")
			data[k] = decodeURIComponent(v)
		return data

	componentWillMount: ->
		qs = @getQs()

		if qs.remote is "1"
			@isRemote = true

		unless qs.warn is "0"
			window.onbeforeunload = =>
				if State.get().resource
					"If you leave this page you will lose any unsaved changes."

		defaultProfilePath = "./profiles/dstu2.json"
		State.trigger "load_profiles", 
			qs.profiles || defaultProfilePath,
			qs.resource, @isRemote

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
		else if !state.bundle and state.ui.status.indexOf("error") is -1
			<div className="row" style={marginTop: "20px"}><div className="col-xs-offset-4 col-xs-4">
				<button className="btn btn-primary btn-block" onClick={@handleOpen.bind(@)}>
					Open Resource
				</button>
			</div></div>

		error = if state.ui.status is "profile_error"
			<div className="alert alert-danger">An error occured loading the resource profiles.</div>
		else if state.ui.status is "load_error"
			<div className="alert alert-danger">An error occured loading the resource.</div>
		else if state.ui.status is "validation_error"
			<div className="alert alert-danger">Please fix errors in resource before continuing.</div>

		navBar = if @isRemote
			<RemoteNavbar 
				hasResource={if state.resource then true}
				appVersion={@appVersion} 
				hasProfiles={state.profiles isnt null}
			/>
		else
			<Navbar hasResource={if state.resource then true} appVersion={@appVersion} />

		<div>
			{navBar}
			<div className="container" style={marginTop: "50px", marginBottom: "50px"}>
				{bundleBar}
				{error}
				{resourceContent}
			</div>
			<OpenDialog show={state.ui.status is "open"} openMode={state.ui.openMode} />
			<ExportDialog show={state.ui.status is "export"}
				bundle={state.bundle}
				resource={state.resource}
			/>
		</div>


ReactDOM.render <RootComponent />, document.getElementById("content")
