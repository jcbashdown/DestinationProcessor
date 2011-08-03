#p "Enter taxonomy.xml location"
#taxonomy = gets.chomp
#p "Enter destinations.xml location"
#destinations = gets.chomp
#p "Enter output path"
#output_path = gets.chomp
#todo - put these chomps in when done testing. or opt args?


module DestinationProcessor
  #include libxml-ruby xml parser.
  require 'xml'
  require 'titleize'

  def self.process(taxonomy, destinations, output_path)
    p "Parsing files..."
    p "Taxonomy: #{taxonomy}"
    p "Destinations: #{destinations}"
    p "Writing to output folder: #{output_path}"
    parser_tax = XML::Parser.file(taxonomy)
    parser_dest = XML::Parser.file(destinations)
    p  "Parsing destination taxonomy..."
    tax = parser_tax.parse
    p  "Parsing destination descriptions..."
    dest_descript = parser_dest.parse
    p  "Destinations into nodes..."
    all_destinations = tax.find('/taxonomies/taxonomy//node')

    p  "Gathering information..."
    all_destinations.each do |destination|
      id = destination["atlas_node_id"]
      name = get_destination_name(id, destination)
#     figure out local taxonomy...
#     parents...
      if destination.parent?
        unless destination.parent["atlas_node_id"].nil?
          parent_id = get_parent_id(destination)
          parent_name = get_parent_name(parent_id, destination)
          p "#{name} is child of #{parent_name}"
        end
      end
#     children...
      contained_destinations = get_contained_destinations(destination, id, name)
#     can now write navigation
      p "#{contained_destinations} are children of #{name}"
      p  "Gathering text..."
      text = gather_text(id, dest_descript)
      p  "Writing page..."
      write_page(name, text, contained_destinations, parent_name, output_path)
    end
  end

  def self.get_destination_name(id, destination)
#   destination.first (to get first child node) was returning empty nodes so we have this ugliness
    destination.find_first("//node[@atlas_node_id='#{id}']/node_name").content
  end

  def self.get_parent_id(destination)
    destination.parent["atlas_node_id"]
  end

  def self.get_parent_name(parent_id, destination)
#   and this...
    destination.find_first("//node[@atlas_node_id='#{parent_id}']/node_name").content
  end

  def self.get_contained_destinations(destination, id, name)
    contained_destinations = Array.new
#   again..
    destination.find("//node[@atlas_node_id='#{id}']/node/node_name").each do |child|
      unless child.content==name
        contained_destinations<< child.content
      end
    end
    contained_destinations
  end

  def self.gather_text(id, dest_descript)
    text = ""
    all_text = dest_descript.find("//destination[@atlas_id='#{id}']//*")
    previous_name=""
    all_text.each_with_index do |child,i|
#     was going to do something clever with levels and headings here but it's probably a bit much
#     without a good way to do it.
      level=1
      unless child.name=="#{previous_name}" then text+="<h#{level}>#{child.name.gsub("_", " ").titleize}</h#{level}>" end
      previous_name=child.name
#     you'd think something like finding out if this is a leaf node or if it had a sub text
#     node would do this but apparently everything does so each with index...
      unless all_text[i+1].nil?
        unless child.content.include?(all_text[i+1].content) then text+="<p>#{child.content}</p>" end
      end
    end
    text
  end

  def self.write_page(name, text, contained_destinations, parent_name, output_path)
    sub_destinations=""
    unless contained_destinations.empty?
      contained_destinations.each do |destination|
        sub_destinations+='&nbsp;&nbsp&nbsp;&nbsp<a href="'+destination.gsub(/\s/, "_")+'.html">'+destination+'</a><br/><br/>'
      end
    end
#   There is a nice way to do this. I just can't think of it right now...
    html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
              <html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml" lang="en">

              <head>
                <meta http-equiv="content-type" content="text/html; charset=UTF-8">
                <title>Destinations</title>
                <script src="static/routes.js" type="text/javascript"></script>
                <link href="static/all.css" media="screen" rel="stylesheet" type="text/css">

                <script type="text/javascript" charset="utf-8">
                  imagePath = "/images/"
                </script>



              </head>

              <body>

                <div id="container">
                  <div class="message-wrapper">
                    <div style="overflow: visible; opacity: 1; display: none;" class="flash-messages " id="flash-messages"></div>
                  </div>
                  <div id="header">
                    <div id="logo"></div>
                    <h1>Destination: '+name+'</h1>
                  </div>

                <div id="wrapper">

                <div id="sidebar">
                  <div class="block">
                    <h3>Navigation</h3>
                    <div class="content">
                      <div class="inner">'
    unless parent_name.nil? 
      html+='<a href="'+parent_name.gsub(/\s/, "_")+'.html">'+parent_name+'</a><br/><br/>'
    end
    html+='<b>&nbsp;&nbsp;<a href="'+name.gsub(/\s/, "_")+'.html">'+name+'</a></b><br/><br/>'
    unless sub_destinations.empty?
      html+=sub_destinations
    end
    html+=           '</div>
                    </div>
                  </div>
                </div>

                <div id="main">
                  <div class="block">
                    <div class="secondary-navigation">
                      <ul>
                        <li class="first"><a href="">'+name+'</a></li>
                      </ul>
                      <div class="clear"></div>
                    </div>
                      <div class="content">
                        <div class="inner">
                        '+text+'
              		      </div>
                      </div>
                    </div>
                  </div>
                </div>
                </div>
              <div style="overflow: hidden; position: absolute; display: none; cursor: move; list-style-type: none; list-style-image: none; list-style-position: outside;" id="dragHelper"></div><div style="position: absolute; height: 1px; width: 1px; top: -1000px; left: -1000px;"><span class="ygtvtm">&nbsp;</span><span class="ygtvtmh">&nbsp;</span><span class="ygtvtp">&nbsp;</span><span class="ygtvtph">&nbsp;</span><span class="ygtvln">&nbsp;</span><span class="ygtvlm">&nbsp;</span><span class="ygtvlmh">&nbsp;</span><span class="ygtvlp">&nbsp;</span><span class="ygtvlph">&nbsp;</span><span class="ygtvloading">&nbsp;</span></div></body></html>'
    File.open(output_path+"/"+name.gsub(/\s/, "_")+".html", 'w') {|f| f.write(html) }
  end

end