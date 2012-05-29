## default event handler
class NiceJquery

	# insert element after referencing node
	@insert_after: (event) ->
		$(event.ref_node).after(event.new_node)

	# insert element at first position inside referencing node
	@insert_inside: (event) ->
		$(event.ref_node).prepend(event.new_node)

	# remove all elements which are not of current state and all elements
	# which are of current state and secondly annotated to be always updated.
	@remove_state_elements: (event) ->
		$("[data-state]").not("[data-state~='#{event.curr_state}']").remove()
		$("[data-state~='#{event.curr_state}'][data-state-update!='no']").remove()


	# Browser History Stuff
	@move_to_url: (event) ->
  		history.pushState(null,event.title,event.url)
			
	@insert_or_update_back_listener: (event) ->
		# remove current existing back-binders
		$(window).unbind('popstate')
		$(window).bind('popstate', -> 
			xmlHttp = null
			xmlHttp = new XMLHttpRequest()
			xmlHttp.open('GET', event.url, false)
			xmlHttp.send(null)
			eval(xmlHttp.responseText)
		)


## add event listener
document.addEventListener "nice.dom.InsertAfterEvent", NiceJquery.insert_after, false
document.addEventListener "nice.dom.InsertInsideEvent", NiceJquery.insert_inside, false
document.addEventListener "nice.dom.RemoveStateEvent", NiceJquery.remove_state_elements, false
document.addEventListener "nice.hist.ChangeURLEvent", NiceJquery.move_to_url, false
document.addEventListener "nice.hist.PopHistoryEvent", NiceJquery.insert_or_update_back_listener, false