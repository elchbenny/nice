require 'nokogiri'
require 'yaml'
require 'nice/js/caller'

module Nice
  class HtmlParser
  
    def self.remove_elements_not_of_state(state, doc)

      doc.css("[data-state]").each do |node|
        state_list = node.attribute('data-state').value.split(" ")

        if  !state_list.include?('all') &&
            !state_list.include?(state) then
          
          p "removed state: #{state_list}"            
          node.remove
        end
      end

      doc
    end

  	def self.add_elements_of_current_state doc, curr_state, upper_root=false

  		# get all nodes of the current state      
      doc.css("*[data-state-root]").remove  if upper_root # for upper_root option remove tree below root to shorten the search
  		curr_state_nodes = doc.css("[data-state~='#{curr_state}']")
  		all_nodes = doc.css("[data-state~='all']")
  		

  		# get reference nodes in DOM tree for current nodes and generate js insert statements
  		stack = curr_state_nodes.reverse.each_with_index.map do |curr_node,index|

        # in case this node is not only assigned to the current state - check if it should be updated
        if curr_node.attribute("data-state").value != curr_state &&
           !curr_node.has_attribute?("data-state-update") then
          next
        end

  			ref_id = self.ref_node_uid( curr_state,curr_state_nodes.count - index)
  			ref_node_name = "[data-state-uid~=\'#{ref_id}\']"  			
  			ref_node = doc.css(ref_node_name)
  			
  			if ref_node.blank?
  			  next
  			end
  			
  			#get index
  			idx = ref_node.attribute("data-state-uid").value.split(" ").find_index(ref_id)

  			ref_node_method = ref_node.attribute('data-state-insert-method').value.split(" ")[idx]

  			if ref_node_method == "insert"
  				js_text = Nice::Js::Caller.generate_js_insert_after curr_node, ref_node_name
  			else
  				js_text = Nice::Js::Caller.generate_js_insert_inside curr_node, ref_node_name
  			end

  			# remove unuseful chars which will break the js parser
  			js_text = js_text.gsub(/(\r\n|\n|\r|\t|\s\s)/,'')
  		end
  		
  		# nodes with 'all' attribute
  		stack += all_nodes.reverse.each_with_index.map do |curr_node,index|

        if !curr_node.has_attribute?("data-state-update") then
          next
        end

  			ref_id = self.ref_node_uid( 'all',all_nodes.count - index)
  			ref_node_name = "[data-state-uid~=\'#{ref_id}\']"  			
  			ref_node = doc.css(ref_node_name)
  			
  			if ref_node.blank?
  			  next
  			end
  			
  			#get index
  			idx = ref_node.attribute("data-state-uid").value.split(" ").find_index(ref_id)

  			ref_node_method = ref_node.attribute('data-state-insert-method').value.split(" ")[idx]

  			if ref_node_method == "insert"
  				js_text = Nice::Js::Caller.generate_js_insert_after curr_node, ref_node_name
  			else
  				js_text = Nice::Js::Caller.generate_js_insert_inside curr_node, ref_node_name
  			end

  			# remove unuseful chars which will break the js parser
  			js_text = js_text.gsub(/(\r\n|\n|\r|\t|\s\s)/,'')
  		end  		

  		stack
  	end

  	# generates referencing data attributes in all preceiding or parent nodes of 
  	# state bound elements which are used later to insert elements correctly
  	# This method supports referencing by more than one state bounded node
  	def self.annotate_referencing_nodes doc

  		per_state_counter = {}
  		doc.css("[data-state]").each do |curr_node|
  			
  			# each node can have multiple state references which need to be
  			# treated separately
  			states = curr_node.attribute("data-state").value.split(" ")

  			states.each do |state|
	  			# increase counter per state
	  			per_state_counter[state] ||= 0
	  			idx = per_state_counter[state] += 1

	  			# try using preceding element if one exists otherwise use parent.
	  			# the referencing node must not be an state bound element otherwise
	  			# we can not be sure the element is always present.
	  			prev_node = curr_node.previous_element

	  			while prev_node && prev_node.has_attribute?("data-state")
	  			 	prev_node = prev_node.previous_element
	  			end 

	  			if prev_node && !prev_node.has_attribute?("data-state")
	  				node = prev_node
	  				method = "insert"	
	  			else
	  				par_node = curr_node.parent
	  				
	  				while par_node && par_node.has_attribute?("data-state")
	  			 		par_node = par_node.parent
	  				end 

	  				if par_node && !par_node.has_attribute?("data-state")
	  					node = curr_node.parent
	  					method = "append"
	  				else
	  					raise "No reference could be created for node #{curr_node}. Make sure this node \
	  					is preceeded or sourrounded at least by one non state bound element."
	  				end
	  				
	  			end

	  			next if node == nil

	  			# add reference to the found element
	  			a = node.has_attribute?('data-state-uid') ? [node.attribute('data-state-uid').value] : []
				a += [self.ref_node_uid(state,idx)]
				node['data-state-uid'] = a.join(" ")

				m = node.has_attribute?('data-state-insert-method') ? [node.attribute('data-state-insert-method').value] : []
				m += [method]
				node['data-state-insert-method'] = m.join(" ")
			end
  		end

  		doc
  	end

	  def self.add_top_css doc, current_state
	    doc.css("body").add_class("state-#{current_state}")
	    doc
	  end
	  
	  def self.add_root_content doc
      if doc.css("[data-state-root]").length == 0
        raise "You must add add a data-state-root in your application.html to your main container"
      else
  			ref_node_name = "[data-state-root]"
  			js = []
  			doc.css("*[data-state-root]").each do |curr_node|
	        js << Nice::Js::Caller.replace_node(curr_node, ref_node_name).gsub(/(\r\n|\n|\r|\t|\s\s)/,'')
        end
        js
	    end
	  end
	
  	private
	
  	def self.ref_node_uid node_uid, num
  		"#{node_uid}_ref_#{num}"
  	end
	
  end
end