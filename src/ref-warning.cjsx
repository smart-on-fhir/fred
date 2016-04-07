React = require "react"
State = require "./state"

class RefWarning extends React.Component

	handleUpdate: (e) ->
		e.preventDefault()
		State.trigger "update_refs", @props.update

	handleCancel: (e) ->
		e.preventDefault()
		State.trigger "set_ui", "ready"	

	render: ->
		countText = if @props.count > 1
			"#{@props.count.toString()} resources " 
		else
			"a resource "
		<div className="alert alert-info text-center" style={marginTop: "10px"}>
			This resource is referenced by {countText} in this Bundle.
			<p style={marginTop: "4px"}>
				<button className="btn btn-primary btn-sm" 
					onClick={@handleUpdate.bind(@)}
				>Update</button>
				<button className="btn btn-default btn-sm" style={marginLeft: "10px"} 
					onClick={@handleCancel.bind(@)}
				>Ignore</button>
			</p>
		</div>


module.exports = RefWarning
