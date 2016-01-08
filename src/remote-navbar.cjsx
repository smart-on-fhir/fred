React = require "react"
State = require "./state"
SchemaUtils = require "./schema-utils"
BsNavbar = require("react-bootstrap").Navbar
{Nav, NavItem} = require("react-bootstrap")

class RemoteNavbar extends React.Component

	componentWillMount: ->
		@launcher = 
			(window.parent unless window.parent is window) or window.opener
			
		window.addEventListener "message", (e) =>
			if e.data?.action is "edit" and e.data?.resource
				State.trigger "load_json_resource", e.data.resource
				@remoteCallback = e.data.callback
		, false
		@launcher.postMessage {action: "fred-ready"}, "*"

	handleSaveRequest: (e) ->
		e.preventDefault()
		[resource, errCount] = SchemaUtils.toFhir State.get().resource, true
		bundle = State.get().bundle
		if bundle then resource = 
			SchemaUtils.toBundle bundle.resources, bundle.pos, resource 		
	
		if errCount > 0
			State.trigger "set_ui", "validation_error"
		else
			@launcher.postMessage
				action: "fred-save", resource: resource, 
				callback: State.get().remoteCallback
			, "*"
			window.close()

	handleCancelRequest: (e) ->
		e.preventDefault()
		@launcher.postMessage
			action: "fred-cancel"
		, "*"
		window.close()

	handleUiChange: (status, e) ->
		e.preventDefault()
		State.trigger "set_ui", status

	renderButtons: ->
		return null unless @props.hasResource
		<Nav>
			<NavItem key="open" onClick={@handleUiChange.bind(@, "open")}>
				Open Resource
			</NavItem>
			<NavItem key="resource_json" onClick={@handleUiChange.bind(@, "export")}>
				Export JSON
			</NavItem>
			<NavItem key="remote_save" onClick={@handleSaveRequest.bind(@)}>
				Save and Close
			</NavItem>
			<NavItem key="remote_cancel" onClick={@handleCancelRequest.bind(@)}>
				Cancel and Close
			</NavItem>
		</Nav>

	render: ->
		<BsNavbar fixedTop={true} className="navbar-custom">
			<BsNavbar.Header>
				<div className="pull-left" style={margin: "10px"}>
					<img src="./img/smart-bug.png" />
				</div>
				<BsNavbar.Brand>
					FRED v0.02
				</BsNavbar.Brand>
				<BsNavbar.Toggle />
			</BsNavbar.Header>
			<BsNavbar.Collapse>
				{@renderButtons()}
			</BsNavbar.Collapse>
		</BsNavbar>

module.exports = RemoteNavbar
