React = require "react"
State = require "./state"
BsNavbar = require("react-bootstrap").Navbar
{Nav, NavItem} = require("react-bootstrap")

class Navbar extends React.Component

	handleSaveRequest: (e) ->
		e.preventDefault()
		State.trigger "save_remote"

	handleCancelRequest: (e) ->
		e.preventDefault()
		State.trigger "cancel_remote"

	handleUiChange: (status, e) ->
		e.preventDefault()
		State.trigger "set_ui", status

	handleDrag: (e) ->
		e.preventDefault()
		return unless (files = e.dataTransfer?.files) and
			(file = files?[0])
		reader = new FileReader()
		reader.onload = (e) -> 
			try
				json = JSON.parse e.target.result
				State.trigger "load_json_resource", json
			catch e
				State.trigger "set_ui", "load_error"

		State.trigger "set_ui", "loading"
		reader.readAsText(file)
	
	renderNavItems: ->
		return [] unless @props.hasResource
			
		navItems = [
			<NavItem key="resource_json" onClick={@handleUiChange.bind(@, "export")}>
				Export JSON
			</NavItem>
		]

		if @props.isRemote
			navItems.push <NavItem key="remote_save" onClick={@handleSaveRequest.bind(@)}>
				Save and Close
			</NavItem>
			navItems.push <NavItem key="remote_cancel" onClick={@handleCancelRequest.bind(@)}>
				Cancel and Close
			</NavItem>
		else 
			navItems.push <NavItem key="open" onClick={@handleUiChange.bind(@, "open")}>
				Open Resource
			</NavItem>

		return navItems

	render: ->
		<BsNavbar fixedTop={true} className="navbar-custom"
			onDragEnter={@handleDrag.bind(@)}
			onDragOver={@handleDrag.bind(@)}
			onDrop={@handleDrag.bind(@)}
			onDragLeave={@handleDrag.bind(@)}
		>
			<BsNavbar.Header>
				<div className="pull-left" style={margin: "10px"}>
					<img src="./img/smart-bug.png" />
				</div>
				<BsNavbar.Brand>
					FRED v0.02
				</BsNavbar.Brand>
				<BsNavbar.Toggle />
			</BsNavbar.Header>
			<BsNavbar.Collapse><Nav>
				{@renderNavItems()}
			</Nav></BsNavbar.Collapse>
		</BsNavbar>

module.exports = Navbar
