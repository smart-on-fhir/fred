React = require "react"

module.exports = class Footer extends React.Component
	render: =>
		<div className="row footer">
			<div className="col-xs-12">
				FRED is project of <a href="https://smarthealthit.org" target="_blank">SMART Health IT</a> and the open source code for the app is available on <a href="https://github.com/smart-on-fhir/fred" target="_blank">Github</a>. To stay updated on the project follow <a href="https://twitter.com/intent/user?screen_name=gotdan" target="_blank">@gotdan</a> and <a href="https://twitter.com/intent/user?screen_name=smarthealthit" target="_blank">@smarthealthit</a> on twitter.
			</div>
		</div>