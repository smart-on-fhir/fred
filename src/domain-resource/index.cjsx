React = require "react"
State = require "../state"
ResourceElement = require "./resource-element"
ElementMenu = require "./element-menu"

class DomainResource extends React.Component

	shouldComponentUpdate: (nextProps) ->
		nextProps.node isnt @props.node

	render: ->
		return null unless node = @props.node

		resourceId = null
		children = [] 
		for child in node.children
			if child.name is "id"
				resourceId = child.value
				
			children.push <ResourceElement 
				key={child.id} node={child} 
				parent={node} 
			/>

		id = if resourceId
			<span className="small">&nbsp;&nbsp;({resourceId})</span>

		<div className="fhir-resource">
			<div className=" fhir-resource-title row"><div className="col-sm-12">
				<h2>
					{node.displayName}
					{id}
					&nbsp;
					<ElementMenu node={node} />
				</h2>
			</div></div>
			{children}
		</div>


module.exports = DomainResource 