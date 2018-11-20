require "HarrisV12/version"
require 'bindata'
require 'json'
require 'zlib'
require 'happymapper'
require 'nokogiri'


class Hash

	  def nested_each_pair
	    self.each_pair do |k,v|
	      if v.is_a?(Hash)
	        v.nested_each_pair {|k,v| yield k,v}
	      else
	        yield(k,v)
	      end
	    end
	  end

end

module HarrisV12





#p="SS017423"
#m="id"
#pl.rows.select {|x| x.send(m).match(/#{p}/)}.size

#rows.select {|x| x.title.match(/#{p}/)}.size
	
	#default harris max chars per id_louth field
	IDLOUTHLEN=8
	#Max ID_EXTENDED VAL
	IDLOUTHMAX=31
	#deault TITLE len
	TITLELEN=16
	#Max TITLE len
	TITLEMAX=31
	#default harris type
	TYPE=0



	#Public search in playlist lst
	#
	#
	def self.search(playlist, method,value)
		p=value
		m= method != "" ? method : "title"
		puts "Searching #{p} in #{m}.."
		return playlist.rows.select {|x| x.send(m).match(/#{p}/)}

	end

	def self.new_lst()
		return Louthinterface.new()
	end

	def self.calc_crc32(pl)
		return Zlib.crc32(pl.rows.to_binary_s)
	end

	# Public: create extended id/title in harris file.
	#
	# hash  - The hash containing value to insert in playlist row.
	# Examples
	#
	#   create_row({:id=>"ciaociao", :title=>"pippo pippo pippo pippo", :som_tc=>"00:00:00:00")
	#   # => {:id=>"ciaociao", :title=>"pippo pippo pipp", :som_tc=>"00:00:00:00", :type=>1, :extended_title=>"o pippo", :extended_title_len=>7} 
	#
	# Returns the modified Hash.
	#
	def self.create_row(hash)
		type_=TYPE

		hash.merge!({:type_=>TYPE}) if hash[:type_] == nil 

		#ID LOUTH SETTING 
		# if id it's more than 8 chars event type must setted to 1
		# 8 chars of id must putted in id and the rest of data in extended_id
		# the len of extended chars must putted in extended_id_len
		# MAX len for ID EXTENDED it's 32 chars
		#
		# => the same operation must done for TITLE 
		#
		old_type		= 	hash[:type_]
		if(hash[:id]!=nil)
			louth 			=	hash[:id]


			if(louth.size>IDLOUTHLEN)
				type_ 				=	1
				louth				= 	louth[0..IDLOUTHMAX]
				id 					=	louth[0..(IDLOUTHLEN-1)]
				extended_id 		= 	louth[IDLOUTHLEN..louth.size]
				extended_id_len		=	louth.size-IDLOUTHLEN

				hash.merge!({:type_=>type_, :id=>id,:extended_id=>extended_id,:extended_id_len=>extended_id_len})
				if (old_type == 160 || old_type == 224 || old_type == 128)
					hash.merge!({ :extended_type=>old_type, :old_type=> old_type})
				end
			end
		end
		#
		# => TITLE SETTTINGS
		#
		if(hash[:title]!=nil)
			title 			=	sanitize(hash[:title])
 
			if(title.size>TITLELEN)
				type_ 				=	1
				old_type			=	old_type
				extended_type		=   extended_type
				title 				= 	title[0..TITLEMAX]
				title_new			=	title[0..(TITLELEN-1)]
				extended_title 		= 	title[TITLELEN..title.size]
				extended_title_len	=	title.size-TITLELEN

				hash.merge!({:type_=>type_, :title=>title_new,:extended_title=>extended_title,:extended_title_len=>extended_title_len})
				if (old_type == 160 || old_type == 224 || old_type == 128)
					hash.merge!({ :extended_type=>old_type, :old_type=> old_type})
				end
			end
		end




		return hash

	end




	# Public: read .lst harris file.
	#
	# hash  - The hash containing value to insert in playlist row.
	# Examples
	#
	#   create_row({:id=>"ciaociao", :title=>"pippo pippo pippo pippo", :som_tc=>"00:00:00:00")
	#   # => {:id=>"ciaociao", :title=>"pippo pippo pipp", :som_tc=>"00:00:00:00", :type=>1, :extended_title=>"o pippo", :extended_title_len=>7} 
	#
	# Returns the modified Hash.
	#
	def self.read_lst(file_lst_path,options={:json=>false})
		f = File.open(file_lst_path,'r:windows-1251:utf-8')
		if(options[:json])
			return Louthinterface.read(f).to_json
		else
			return Louthinterface.read(f)
		end
	end


	# Public: create extended id/title in harris file.
	#
	# hash  - The hash containing value to insert in playlist row.
	# Examples
	#
	#   create_row({:id=>"ciaociao", :title=>"pippo pippo pippo pippo", :som_tc=>"00:00:00:00")
	#   # => {:id=>"ciaociao", :title=>"pippo pippo pipp", :som_tc=>"00:00:00:00", :type=>1, :extended_title=>"o pippo", :extended_title_len=>7} 
	#
	# Returns the modified Hash.
	#
	def self.xml_to_lst(file_xml_path,file_lst_path, options={})

	  default_options = {
	  	# set 1 to all programs in playlist 
	  	# => Enable/Disable
	    :segment_programs => true,
	    :segment_programs_identify=>"PROG",
	    :segment_programs_val => 1,

	    #ABOX <-- tipo2
	    :abox_converted=> true,
	    #BBOX <-- tipo
	    :bbox_converted=>true,

	    # => WRITE destination as json
	    :to_json=>false

	  }

	  options = options.merge!(default_options){|key,left,right| left }
	  puts options

	  obj = Playlist.parse_xml(file_xml_path)
	  #conta=0;
	  rows = []

	  logo_is_on=false
	  
	  obj.primary_events.each do |o|
	    
		    onair_time  = o.tx_time
		    durata_clip = o.tx_duration
		    abox_som    = "00:00:00:00"
		    som_clip = o.pe_components == nil ? abox_som : o.pe_components.component[0].timecode_in
		    tipo = o.event_type
		    tipo2 = o.schedule_event_type
		    segment = tipo ==	options[:segment_programs_identify] ? options[:segment_programs_val] : 255


		    line = {
		    	:type_=>1,
		    	:id=>o.media_id,
		    	:onair_tc=>onair_time,
		    	:som=>som_clip,
		    	:dur=>durata_clip,
		    	:title=>o.title
		    }

		    #Attivo/Disattivo le opzioni
		    # enable/Disable options
		    line.merge!({:segment=>segment})				if options[:segment_programs]
		    line.merge!({:box_aid=>tipo2.ljust(8)}) 		if options[:abox_converted]
		    line.merge!({:b_id=>tipo.ljust(8)}) 			if options[:bbox_converted]

		    rows.push(create_row(line))


	end

	    a= Louthinterface.new(:rows=>rows)


		if(options[:to_json])

		    arr= []
			a.rows.each_with_index do |x,i| 
				hash = {}
				x.each_pair do |k,v| 
					if(v.class == BinData::String)

						hash[k]=sanitize(v)
					else
						hash[k]=v
					end
					
				end
				arr.push(hash)
			end

			puts "TO JSON: TRUE"
		 
			return File.open(file_lst_path,'w') {|f| f.write(arr.to_json) }
		else
			File.open(file_lst_path,'wb') {|f| a.write(f) }

			puts "TO JSON: FALSE"
	 	end
	  
 

	end

  def self.sanitize(stringa)
  	return stringa#.gsub(/\s|”|'|‘|’|\|"/, 32.chr)#.gsub(/–/, "-")#.gsub(/‘|’/, '\'')
  	#string.gsub! /"/, '|'
    #return stringa.gsub!(/#{255.chr}/,"")
    #return stringa
  end

	# Private: Timecode primitive BinData, set value in Harris BCD value
	# => get BCD value and convert it to String with ":" separator
	#
	#
	# Returns "10:00:01:24"
	#
	class BcdTimecode < BinData::Primitive

	  uint8  :valore_fr, :read_length => 1, :initial_value=>0
	  uint8  :valore_sec, :read_length => 1, :initial_value=>0
	  uint8  :valore_min, :read_length => 1, :initial_value=>0
	  uint8  :valore_hours, :read_length => 1, :initial_value=>0

	  def get
	  	return addzero(valore_hours.to_i.to_s(16)) + ":" + addzero(valore_min.to_i.to_s(16)) + ":" + addzero(valore_sec.to_i.to_s(16)) + ":"+ addzero(valore_fr.to_i.to_s(16))
	  end

	  def set(v)
	  	arr = v.split(":").reverse
	  	self.valore_fr		= arr[0].to_i(16)
	  	self.valore_sec		= arr[1].to_i(16)
	  	self.valore_min		= arr[2].to_i(16)
	  	self.valore_hours	= arr[3].to_i(16)
	  end

	  	 def addzero(val)
		      newval=""
		      if val.to_i <= 9 and not val == "ff"
		        newval="0"+val.to_s
		      else
		        return val
		      end
		    return newval
		end 

	end


	# Private: Set/Get BCD value from harris lst file
	#
	# BCD: Binary code decimal
	#
	class Bcd < BinData::Primitive

	  uint8  :valore, :read_length => 1, :initial_value=>255

	  def get
	  	return valore
	  end

	  def set(v)
	  	 self.valore=v
	  end

	end

	class UTF8String < BinData::String
	  def snapshot
	    super.force_encoding('UTF-8')
	  end
	end

	# Private: Harris Louth row structure based on Harris documentation 
	# 
	#
	#
	#
	#
	class LouthRowEasy < BinData::Record

		
					  empty_chr = 32.chr
					  null_chr = 255.chr				 

					 

		  			  uint8le			:type_, :initial_value=>0
	 
		 			  #Extended Event Part
					  #bit16				:extended_type, :read_length=>2, :initial_value=>0, :onlyif => :is_Ext?
					  uint16le			:extended_type, :read_length=>2, :initial_value=>0, :onlyif => :is_Ext?
					  uint8le			:old_type, :initial_value=>0, :onlyif => :is_Ext?
					  #string			:reconcile_key, :read_length=>8, :initial_value=>empty_text
					  string			:reconcile_key,:length => 8,  :pad_byte=>null_chr
			 
		   			  #common part_num
					  uint8le				:effect1, :initial_value=>0
					  uint8le				:effect2, :initial_value=>0
					  uint8le				:effect3, :initial_value=>0
					  #array				:onair_tc, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:onair_tc, :length=>4


					  string			:id, :length => 8,  :pad_byte=>empty_chr#:initial_value=>empty_text,

					  #string			:id, :pad_byte=>empty_chr, :value=> lambda { louth_id[0..7].ljust() }
					  
					  string			:title, :length => 16,:pad_byte=>empty_chr# :initial_value=>empty_text, 
					  #BcdTimecode		:som, :length=>4
					  #array				:som, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:som, :length=>4
					  #BcdTimecode		:dur, :length=>4
					  #array				:dur, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:dur, :length=>4

					  uint8le			:channel, :initial_value=>0
					  uint8le			:qualifier4, :initial_value=>0
					  Bcd				:segment, :length=>1

					  uint8le			:devmajor, :initial_value=>0
					  uint8le			:devmin, :initial_value=>0
					  
					  uint8le			:binhigh, :initial_value=>0
					  uint8le			:binlow, :initial_value=>0

					  uint8le			:qualifier1, :initial_value=>0
					  uint8le			:qualifier2, :initial_value=>0
					  uint8le			:qualifier3, :initial_value=>0

					  uint16le			:date_on_air, :initial_value=>0
					  uint16le			:event_control, :initial_value=>7
					  uint16le			:status, :initial_value=>0

					  string			:compile_id, :length => 8,  :pad_byte=>null_chr

					  #BcdTimecode		:compile_som, :length=>4
					  #array				:compile_som, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:compile_som, :length=>4

					  string			:box_aid, :length => 8,  :pad_byte=>null_chr

					  #BcdTimecode		:a_som, :length=>4
					  #array				:a_som, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:a_som, :length=>4

					  string			:b_id, :length => 8,  :pad_byte=>null_chr

					  #BcdTimecode		:b_som, :length=>4
					  #array				:b_som, :type=>BcdTimecode2, :initial_length=>4
					  BcdTimecode		:b_som, :length=>4

					  uint8le			:reserved, :initial_value=>0 #fillwith 0 always
					  uint8le 			:backup_dev_maj, :initial_value=>0
					  uint8le			:backup_dev_min, :initial_value=>0
					  uint8le			:reserved2, :initial_value=>0

					  #Extended part of title
					  uint16le 			:extended_id_len,:value => lambda { extended_id.length },  :onlyif => :is_Ext?
					  string			:extended_id, :read_length => :extended_id_len, :onlyif => :ext_id_exist?
					  uint16le			:extended_title_len, :value => lambda { extended_title.length }, :onlyif => :is_Ext?
					  string			:extended_title, :read_length => :extended_title_len, :onlyif => :ext_title_exist?
			
					  virtual			:louth_id, 		:value=>lambda{ id + extended_id}
					  virtual			:louth_title, 	:value=>lambda{ title + extended_title}
		

		# Private: check if row is extended
		#
		def is_Ext?
			if type_==1		 
				return true
			else
				return false
			end
		end

		# Private: check if id is ext
		#		
		def ext_id_exist?
			if type_==1 && extended_id_len>0		 
				return true
			else
				return false
			end
		end

		# Private: check if title is extended
		#
		def ext_title_exist?
			if type_==1 && extended_title_len>0			 
				return true
			else
				return false
			end
		end


	end

	# Public: Read/Write Harris playlist file using BinData.read BinData.write
	#
	# => 
	# => 
	# => 
	# => 
	#
#	class Louthinterface < BinData::Record
#
#		array :rows, :type=> LouthRowEasy, read_until: :eof
#
#	end


	class Louthinterface < BinData::Record

		string :signature, :length=>11, :initial_value=>"PLAYLISTVER"
		string :list_version, :length=>2, :initial_value=>"12"
		string :reserved,	:length => 39,	:pad_byte=>"-"
		string :create_date, :length=>8, :initial_value=>"01012018"
		uint32le :crc32, :length=> 4,:initial_value=>0	
		array :rows, :type=> LouthRowEasy, read_until: :eof	

	end	





	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 
	#
	#
	#
	class Component
		  include HappyMapper
		  tag 'component'

		  element 'material_uid', String
		  element 'parent_event_uid', String
		  element 'parent_event_type', String
		  element 'component_type', String
		  element 'material_type', String
		  element 'tx_id', String
		  element 'barcode', String
		  element 'language', String
		  element 'tracks', String, :attributes => {:num_of_tracks=>String}
		  element 'status', String
		  element 'part_num', String
		  element 'segment_num', String
		  element 'timecode_in', String
		  element 'duration', String
		  element 'timecode_out', String
	end

	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 
	#
	#
	#	
	class SecondaryEvents
		  include HappyMapper
		  tag 'secondary_event'

		  element 'se_uid', String
		  element 'se_type', String
		  element 'se_title', String
		  element 'se_offset', String
		  element 'se_duration', String
		  element 'se_comment', String
		  element 'se_tx_source', String

	end

	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 
	#
	#
	#
	class PeComponent
		  include HappyMapper
		  tag 'pe_components'

		  attribute :num_of_pe_components, String

		  has_many :component, Component, :tag => 'component'

	end

	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 
	#
	#
	#
	class SecondaryEvent
		  include HappyMapper
		  tag 'secondary_events'

		  attribute :num_of_se_events, String

		  has_many :secondary_event, SecondaryEvents, :tag => 'secondary_event'

	end

	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 
	#
	#
	#
	class PrimaryEvent
		  include HappyMapper
		  tag 'primary_event'

		  element 'recon_uid', 					String
		  element 'external_spot_id', 			String
		  element 'event_type', 				String
		  element 'schedule_event_type',		String
		  element 'prog_type', 					String,			 :state_when_nil => true
		  element 'tx_source', 					String
		  element 'plan_event_date', 			Date,			 :on_save => lambda {|plan_event_date| plan_event_date.strftime("%d/%m/%Y") if plan_event_date }
		  element 'plan_event_time', 			String 
		  element 'plan_duration', 				String
		  element 'media_id', 					String 
		  element 'tx_date', 					Date,			 :on_save => lambda {|tx_date| tx_date.strftime("%d/%m/%Y") if tx_date }
		  element 'tx_time', 					String 
		  element 'tx_duration', 				String 
		  element 'local_tx_time', 				String 
		  element 'local_tx_time_30hr_clock', 	String 
		  element 'season_name', 				String 
		  element 'season_number', 				String 
		  element 'production_type', 			String 
		  element 'production_companies', 		String 
		  element 'deal_sub_type', 				String 
		  element 'country', 					String 
		  element 'season_name', 				String,			 :state_when_nil => true
		  element 'season_number', 				String,			 :state_when_nil => true
		  element 'title', 						String 
		  element 'title_uid', 					String 
		  element 'version_uid', 				String 
		  element 'version_type', 				String
		  element 'ratio', 						String 
		  element 'resolution', 				String 
		  element 'episode_number', 			String 
		  element 'premiere', 					String 
		  element 'max_parts', 					String 
		  element 'title_2', 					String
		  element 'epg_title', 					String
		  element 'genre', 						String
		  element 'sub_genre', 					String

		  has_one :pe_components, PeComponent, :tag => 'pe_components'
		  has_one :secondary_events, SecondaryEvent, :tag =>'secondary_events'

	end


	# Private: use HappyMapper to read Disney XML file and convert it to Ruby Object
	# 		   user nokogiri and HappyMapper to parse XML file	
	#
	#
	#
	class Playlist

	  #attrib_accessor :parse_attached
	  include HappyMapper
	  tag 'playlist'

	  attribute :num_of_primary_events, String, :state_when_nil => true
	  #attribute :realtime_end, String, :state_when_nil => true
	  has_many :primary_events, PrimaryEvent, :tag => 'primary_event'



	  def self.to_disney_xml(object)


	    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
	      xml.playlist('num_of_primary_events' => object['primary_events'].size) {
	       
	          object['primary_events'].each do |o|
	             xml.primary_event {
	              
	                      xml.recon_uid                         o['recon_uid']
	                      xml.external_spot_id                  o['external_spot_id']
	                      xml.event_type                        o['event_type']
	                      xml.schedule_event_type               o['schedule_event_type']
	                      xml.tx_source                         o['tx_source']
	                      xml.plan_event_date                   o['plan_event_date']
	                      xml.plan_event_time                   o['plan_event_time']
	                      xml.plan_duration						o['plan_duration']
	                      xml.media_id                          o['media_id'] 
	                      xml.tx_date                           o['tx_date'] 
	                      xml.tx_time                           o['tx_time'] 
	                      xml.tx_duration                       o['tx_duration'] 
	                      xml.local_tx_time                     o['local_tx_time'] 
	                      xml.local_tx_time_30hr_clock          o['local_tx_time_30hr_clock'] 
	                      xml.season_name                       o['season_name'] 
	                      xml.season_number                     o['season_number'] 
	                      xml.production_type                   o['production_type'] 
	                      xml.production_companies              o['production_companies'] 
	                      xml.deal_sub_type                     o['deal_sub_type'] 
	                      xml.country                           o['country'] 
	                      xml.season_name                       o['season_name'] 
	                      xml.season_number                     o['season_number'] 
	                      xml.title                             o['title'] 
	                      xml.title_uid                         o['title_uid'] 
	                      xml.version_uid                       o['version_uid'] 
	                      xml.version_type                      o['version_type']
	                      xml.ratio                             o['ratio'] 
	                      xml.resolution                        o['resolution'] 
	                      xml.episode_number                    o['episode_number'] 
	                      xml.premiere                          o['premiere'] 
	                      xml.max_parts                         o['max_parts'] 
	                      xml.title_2                           o['title_2']
	                      xml.epg_title                         o['epg_title']
	                      xml.genre                             o['genre']
	                      xml.sub_genre                         o['sub_genre']

	               
	                  next if o['pe_components'] == nil
	                xml.pe_components("num_of_pe_components"=>o['pe_components']['component'].size) {
	                   o['pe_components']['component'].each do |pe|
	                   
	                    begin
	                      #Rails.logger.debug(pe['component'])

	                   xml.component {

	                      xml.material_uid            pe['material_uid']
	                      xml.parent_event_uid        pe['parent_event_uid']
	                      xml.parent_event_type       pe['parent_event_type']
	                      xml.component_type          pe['component_type']
	                      xml.material_type           pe['material_type']
	                      xml.tx_id                   pe['tx_id']
	                      xml.part_num                pe['part_num']
	                      xml.segment_num             pe['segment_num']
	                      xml.timecode_in             pe['timecode_in']
	                      xml.duration                pe['duration']
	                      xml.timecode_out            pe['timecode_out']

	                   }

	                    rescue
	                      #Rails.logger.debug(pe)
	                    end
	                
	                  end  
	                }

	                next if o['secondary_events'] == nil

	                  xml.secondary_events("num_of_se_events"=>o['secondary_events']['secondary_event'].size) {
	                    o['secondary_events']['secondary_event'].each do |se|
	                      begin
	                    
	                    xml.secondary_event {

	                        xml.se_uid              se['se_uid']
	                        xml.se_type             se['se_type']
	                        xml.se_title            se['se_title']
	                        xml.se_offset           se['se_offset']
	                        xml.se_duration         se['se_duration']
	                        xml.se_comment          se['se_comment']
	                        xml.se_tx_source        se['se_tx_source']

	                    } 
	                      rescue
	                      end

	                    end
	                  }


	              
	            }    
	          end
	     
	      }
	    end
	    return builder.to_xml
	  end


	  	# Public: Return the ruby object(Array of Hash)
	  	# 
	  	# => path: File path to read xml only Disney Version 
	  	#
	  	# @playlit public accessible object
	  	#
	  	#
	    def self.parse_xml(file_path)
	      #f_path = Upload.find(id).attachment_url(:v2)
	     f = File.read(file_path)
	     @playlist = Playlist.parse(f, :single => true)
	    end


	end

end

