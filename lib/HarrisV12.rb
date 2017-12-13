require "HarrisV12/version"
require 'bindata'
#require 'nokogiri'
require 'json'
require 'zlib'

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

	def self.write_lst(file,pl)
		pl.crc
		File.open(file,"wb") do |f| pl.write(f) end 
	end

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

	# Private: Harris Louth row structure based on Harris documentation 
	# 
	#
	#
	#
	#
	class LouthRowEasy < BinData::Record
		require 'bindata'
		
					  empty_chr = 32.chr
					  null_chr = 255.chr				 

		  			  uint16le		:type_,	:initial_value=>0
		  			  string		:key_,	:length => 8,	:pad_byte=>0
		  			  string		:reconcile_key,	:length => 32,	:pad_byte=>empty_chr
		  			  #effects
					  int8			:effect1, :initial_value=>0
					  int8			:effect2, :initial_value=>0
					  int8			:effect3, :initial_value=>0
					  #OnairTimecode
					  BcdTimecode	:onair_tc, :length=>4
					  #Id
					  string		:id,	:length => 32,	:pad_byte=>empty_chr
					  #title
					  string		:title,	:length => 32,	:pad_byte=>empty_chr
					  #SOM
					  BcdTimecode	:som, :length=>4		
					  #SOM
					  BcdTimecode	:dur, :length=>4		
					  int8			:channel, :initial_value=>0
					  Bcd			:segment, :length=>1
					  int8			:devmajor, :initial_value=>0
					  int8			:devmin, :initial_value=>0
					  int8			:binhigh, :initial_value=>0
					  int8			:binlow, :initial_value=>0
					  int8			:qualifier1, :initial_value=>0
					  int8			:qualifier2, :initial_value=>0
					  int8			:qualifier3, :initial_value=>0
					  int8			:qualifier4, :initial_value=>0
					  int16le		:date_on_air, :initial_value=>0
					  int16le		:event_control, :initial_value=>7
					  int32le		:event_status, :initial_value=>0
					  string		:compile_id, :length => 32,  :pad_byte=>0
					  BcdTimecode	:compile_som, :length=>4
					  string		:box_a_id, :length => 32,  :pad_byte=>0	
					  BcdTimecode	:box_a_som, :length=>4
					  string		:box_b_id, :length => 32,  :pad_byte=>0	
					  BcdTimecode	:box_b_som, :length=>4
					  int8			:mspotcontrol, :initial_value=>0 #fillwith 0 always				 
					  int8 			:backup_dev_maj, :initial_value=>0
					  int8			:backup_dev_min, :initial_value=>0		
					  int16le		:extended_event_control, :initial_value=>0		
					  int8			:closed_caption, :initial_value=>0
					  int8			:afd_bar_data, :initial_value=>0	
					  string		:dial_norm,	:length => 4,	:pad_byte=>0
					  string		:db_key,	:length => 4,	:pad_byte=>0	
					  string		:fields_from_source,	:length => 8,	:pad_byte=>0	
					  string		:fields_to_source,	:length => 8,	:pad_byte=>0	
					  string		:reserved,	:length => 64,	:pad_byte=>0
					  int16le		:reserved_buffer_len,	:length => 2,	:pad_byte=>0
					  string		:reserved_buffer, :length=>:reserved_buffer_len
					  int16le		:rating_len,	:length => 2,	:pad_byte=>0
					  string		:rating, :length=>:rating_len
					  int16le		:show_id_len,	:length => 2,	:pad_byte=>0
					  string		:show_id, :length=>:show_id_len	
					  int16le		:show_description_len,	:length => 2,	:pad_byte=>0
					  string		:show_description, :length=>:show_description_len	

					  uint16le		:extended_data_len, :value => lambda { extended_data.length }, :onlyif => :is_extended_data?
					  string		:extended_data, :read_length => :extended_data_len, :onlyif => :is_extended_data?	
					  virtual		:extended_data_json, :read_length => :extended_data_len, :onlyif => :is_extended_data?

					  #pl.rows[0].extended_data = JSON.pretty_generate js

					  def extended_data_json
					  	extended_data_json = JSON.parse(extended_data)
					  end

					  def is_extended_data?
						if type_==416		 
							return true
						else
							return false
						end
					  end			  
	end


	class LouthHeader < BinData::Record
			string :signature, :length=>11, :initial_value=>"PLAYLISTVER"
			string :list_version, :length=>2, :initial_value=>"12"
			string :reserved,	:length => 39,	:pad_byte=>"-"
			string :create_date, :length=>8, :initial_value=>"4å¡¬Ôä@"
			uint8 :crc32, :length=> 4,:initial_value=>0	

			array :rows, :type=> LouthRowEasy, read_until: :eof


		def crc
			self.crc32 =  Zlib.crc32(self.rows.to_binary_s)
		 
		end

	end
	# Public: Read/Write Harris playlist file using BinData.read BinData.write
	#
	# => 
	# => 
	# => 
	# => 
	#
	class Louthinterface < BinData::Record
		#choice :version, :selection => lambda { ... } do
		#    type key, :param1 => "foo", :param2 => "bar" ... # option 1
		#    type key, :param1 => "foo", :param2 => "bar" ... # option 2
		#end
		string :signature, :length=>11, :initial_value=>"PLAYLISTVER"
		string :list_version, :length=>2, :initial_value=>"12"
		string :reserved,	:length => 39,	:pad_byte=>"-"
		string :create_date, :length=>8, :initial_value=>"4å¡¬Ôä@"
		uint32le :crc32, :initial_value=>0#,:asserted_value => lambda { Zlib.crc32(rows.to_binary_s) }	
		#virtual :crc32, :asserted_value => lambda { Zlib.crc32(rows.to_binary_s) }	

		array :rows, :type=> LouthRowEasy, read_until: :eof

		#v12
		#
		#virtual :crc32, :asserted_value => lambda { Zlib.crc32(rows.to_binary_s) }		

	end





end
