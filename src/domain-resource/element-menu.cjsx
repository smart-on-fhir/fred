React = require "react"
State = require "../state"
{Dropdown, MenuItem} = require("react-bootstrap")

class ElementMenu extends React.Component

	shouldComponentUpdate: (nextProps) ->
		nextProps.node?.ui?.menu isnt @props.node?.ui?.menu

	handleToggle: (show) ->
		if show
			State.trigger("show_object_menu", @props.node, @props.parent)

	handleAddItem: (unused) ->
		State.trigger("add_object_element", @props.node, unused)

	handleAddObject: (e) ->
		State.trigger("add_array_object", @props.node)
		e.preventDefault()

	handleMove: (down, e) ->
		State.trigger("move_array_node", @props.node, @props.parent, down)
		e.preventDefault

	handleDeleteItem: (e) ->
		State.trigger("delete_node", @props.node, @props.parent)
		e.preventDefault()

	preventDefault: (e) ->
		e.preventDefault()


	render: ->
		<Dropdown id="element-menu" onToggle={@handleToggle.bind(@)}>
			{@renderToggle()}
			{@renderMenu()}
		</Dropdown>

	renderToggle: ->
		if @props.display is "inline"
			className = "inline-menu-toggle"
			title = @props.node.displayName
	
		else if @props.display is "heading"
			className = "heading-menu-toggle"
			title = @props.parent.displayName

		<Dropdown.Toggle className={className} bsSize="small" title={title || "Add Element"}/>

	renderPlaceholder: ->
		<Dropdown.Menu><MenuItem>Loading...</MenuItem></Dropdown.Menu>

	renderMenu: ->
		unless @props.node?.ui?.status is "menu"
			return @renderPlaceholder() 

		addObject = if @props.node.nodeType is "objectArray"
			<MenuItem onSelect={@handleAddObject.bind(@)}>Add {@props.node.displayName}</MenuItem>
		moveUp = if @props.node.ui.menu.canMoveUp
			<MenuItem onSelect={@handleMove.bind(@, false)}>Move Up</MenuItem>
		moveDown = if @props.node.ui.menu.canMoveDown
			<MenuItem onSelect={@handleMove.bind(@, true)}>Move Down</MenuItem>
		unusedElements = for unused, i in @props.node.ui.menu.unusedElements || []
			required = if unused.isRequired then "*" else ""
			<MenuItem key={i} onSelect={@handleAddItem.bind(@, unused)}>
				{unused.displayName + (required || "")}
			</MenuItem>
		remove = if @props.parent
			<MenuItem onSelect={@handleDeleteItem.bind(@)}>Remove</MenuItem>
		spacer1 = if (addObject or remove)
			<MenuItem divider />
		spacer2 = if (moveUp or moveDown) and unusedElements?.length > 0
			<MenuItem divider />
		header = if unusedElements?.length > 0 and @props.parent
			<MenuItem header>Add Item</MenuItem>

		#handle empty contained resources
		if @props.node?.fhirType is "Resource"
			header = unusedElements = spacer1 = spacer2 = null

		<Dropdown.Menu>
			{remove}{addObject}
			{spacer1}{moveUp}{moveDown}
			{spacer2}{header}{unusedElements}
		</Dropdown.Menu>

module.exports = ElementMenu