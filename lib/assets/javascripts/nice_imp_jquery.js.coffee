## default event handler
class NiceJquery
	
	# css top class manipulation
	@change_top_css: (event) ->
		# remove global state class and add new one
		reg = /// ^
				state-\S+
		///
		matches = $("body").attr("class")?.match(reg)
		$("body").removeClass(c_name) for c_name in matches if matches?
		$("body").addClass("state-#{event.new_state_name}")	

	# insert element after referencing node
	@insert_after: (event) ->
		act = (ref,ins) -> ref.after(ins)
		NiceJquery.perform_transition(event.ref_node, event.new_node, act)

	# insert element at first position inside referencing node
	@insert_inside: (event) ->
		act = (ref,ins) -> ref.prepend(ins)		
		NiceJquery.perform_transition(event.ref_node, event.new_node, act)
		
	# replace ref node with new node
	@replace: (event) ->
		act = (ref,ins) -> ref.replaceWith(ins)
		NiceJquery.perform_transition(event.ref_node, event.new_node, act)		

	# remove all elements which are not of current state and all elements
	# which are of current state and secondly annotated to be always updated.
	@remove_state_elements: (event) ->
		a = jQuery.makeArray( $("[data-state]").not("[data-state~='#{event.curr_state}']").not("[data-state~='all']") )
		a = a.concat jQuery.makeArray( $("[data-state~='#{event.curr_state}'][data-state-update]").not("[data-state~='all']") )
		a = a.concat jQuery.makeArray( $("[data-state~='all'][data-state-update]") )
		
		for elem in a
			transition = $(elem).data('state-transition-class')
			console.log "######## REMOVE ELEMENT: #{elem}"
			if( transition ) 
				$(elem).bind 'transitionend webkitTransitionEnd oTransitionEnd otransitionend', (e) ->
					$(this).remove()					
				$(elem).addClass(transition)
			else    
				$(elem).remove()
				
		return null


	# remove everything under the "root tag"
	@clean_root_tree: (event) ->
		$("[data-state-root]").children().remove()

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
	
	
	# each DOM Manipulation should call this method which will apply the transition animation start values 
	# to the elements before inserting into the DOM tree and the trigger the animation
	@perform_transition: (elem_ref, elem_new, action) ->
		
		# get jquery obj of element to insert
		e = $(elem_new)
		e_ref = $(elem_ref)
		return if !e? || !e_ref?
		
		filter = '[data-state-transition][data-state-transition!="none"]'
		animated_elements = e.find('*').andSelf().filter(filter)
				
		styles = []
		durations = []
		easing = []
		
		animated_elements.each (index,elem) => 
		
			# get transition style
			a_e = $(elem)
			transition = a_e.data('state-transition')
		
			# get custom defined transition definitions
			if( NiceTransitions? )				
				transition_def = if(transition) then NiceTransitions[transition] else NiceTransitions.default		
	
			# if no custom definitions exist - generate a default to do something at least
			if( !transition_def? )
				if transition?
					console.log("Custom Transition Definition for \"#{transition}\" is \
					missing! Please create a NiceTransitions class and configure your transitions.")
		
				# rescue default transition		
				transition_def = 
					duration: 200
					easing: "linear"
					properties:
						opacity: 0.0
						
			durations.push transition_def.duration
			easing.push transition_def.easing
				
			# get current style values and apply start values
			style = {}
			for style_key, style_val of transition_def.properties
				old_value = a_e.css(style_key)
				a_e.css(style_key, style_val)
				style[style_key] = old_value
							
			styles.push style
						
		# insert element
		action(e_ref, e)
		
		# animate		
		animated_elements.each (index,elem) => 
			$(elem).animate(styles[index],durations[index],easing[index]) if styles[index]?

## add event listener
document.addEventListener "nice.dom.InsertAfterEvent", NiceJquery.insert_after, false
document.addEventListener "nice.dom.InsertInsideEvent", NiceJquery.insert_inside, false
document.addEventListener "nice.dom.ReplaceEvent", NiceJquery.replace, false
document.addEventListener "nice.dom.RemoveStateEvent", NiceJquery.remove_state_elements, false
document.addEventListener "nice.dom.ChangeTopCssEvent", NiceJquery.change_top_css, false
document.addEventListener "nice.dom.CleanRootEvent", NiceJquery.clean_root_tree, false
document.addEventListener "nice.hist.ChangeURLEvent", NiceJquery.move_to_url, false
document.addEventListener "nice.hist.PopHistoryEvent", NiceJquery.insert_or_update_back_listener, false

