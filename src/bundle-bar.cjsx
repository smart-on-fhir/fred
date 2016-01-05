React = require "react"
State = require "./state"

class BundleBar extends React.Component

	shouldComponentUpdate: (nextProps) ->
		nextProps.bundle isnt @props.bundle

	handleGoNext: (e) ->
		e.preventDefault()
		State.trigger "set_bundle_pos", @props.bundle.pos+1

	handleGoPrev: (e) ->
		e.preventDefault()
		State.trigger "set_bundle_pos", @props.bundle.pos-1

	renderEmptyBundle: ->
			<div className="alert alert-danger">An error occured loading the resource.</div>

	renderBar: ->
		pos = @props.bundle.pos+1
		count = @props.bundle.resources.length

		<div className="row">
			<form className="navbar-form pull-right">
				<button className="btn btn-default btn-sm" disabled={pos is 1} onClick={@handleGoPrev.bind(@)}>
					<i className="glyphicon glyphicon-chevron-left" />
				</button>
			    <span className="form-control-static" style={marginRight: "10px", marginLeft: "10px"}>
			    	{pos} of {count}
			    </span>
				<button className="btn btn-default btn-sm" disabled={pos is count} onClick={@handleGoNext.bind(@)}>
					<i className="glyphicon glyphicon-chevron-right" />
				</button>
			</form>
		</div>

	render: ->
		if @props.bundle.resources.length > 0
			@renderBar()
		else
			@renderEmptyBundle()

module.exports = BundleBar