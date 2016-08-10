require 'net/http'
require 'tempfile'

class Chef
	class REST
		def streaming_request(url,headers,local_path,&block)
      		uri = URI(url)
			chunk_minimum = 1048576 * 2  # 1 Mb * 2
			num_chunk_max = 10          # maximum of part download in parallel
			content_length = 0
			accept_ranges = ""
			parts_details = []

			ssl = uri.scheme == "https" ? true : false
			Net::HTTP.start(uri.host,uri.port, :use_ssl => ssl){ |http|
				headers = http.head(uri.path).to_hash
				content_length = headers["content-length"][0].to_i
				accept_ranges = headers["accept-ranges"][0]
			}

			unless (accept_ranges == "bytes") || (content_length >= chunk_minimum )
				# doesn't support range request
				parts_details.push({'slot' => 0, 'start' => 0, 'end' => content_length})
			else
				# server support range request
				parts_details = calculate_parts(content_length,num_chunk_max,chunk_minimum)
			end

			local_tmp = fetch(uri,local_path,parts_details)
    	end

		def fetch(uri,local_path,parts,resume=false)
			full_path = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
			Chef::Log.info("Fetching resume is set to #{resume}")
			Chef::Log.info("Remote: #{full_path}")
			Chef::Log.info("Local: #{local_path}")
			Chef::Log.info("Fetching in #{parts.length} parts")
			Chef::Log.debug("Part details: #{pp parts.inspect}")
			# todo.. resume mode
			install_gem_output = `gem install parallel` #install parallel gem
			require 'parallel'

			download_start = Time.now
			Chef::Log.info("Fetching start at #{download_start}")

			Parallel.map(parts,in_threads: 5) do |part|
				part_file = "#{local_path}.#{part['slot']}.tmp"
				download_file(part,full_path,part_file)
			end

			download_elapsed = Time.now - download_start

			Chef::Log.info("Download took #{download_elapsed} seconds to complete")

			failure_flag = false

			parts.each do |part|
				part_file = "#{local_path}.#{part['slot']}.tmp"
				size = File.size(part_file) - 1 #offset by one, part of calculation of start + 1
				unless part['end'] == '' 
					part_size = part['end'] - part['start']
					unless size == part_size
						Chef::Log.warn("File: #{part_file} does not seem to complete its download, please retry and verify")
						failure_flag = true
					end
				end
			end

			unless !failure_flag
				Chef::Log.fatal("File: #{local_path} failed to complete its download")
				return nil
			end

			assemble_start = Time.now

			Chef::Log.info("Assembling parts start at #{assemble_start}")

			tmp_file = assemble_file(local_path,parts)
			assemble_elapsed = Time.now - assemble_start

			Chef::Log.info("Assembling took #{assemble_elapsed} seconds to complete")

			tmp_file
		end

		def assemble_file(local_path,parts)
			temp_file = Tempfile.new(File.basename(local_path,".*"),File.dirname(local_path),'wb+')
			temp_file.binmode

			parts.each do |part|
				file="#{local_path}.#{part['slot']}.tmp"
				temp_file.write(File.open(file,'rb').read)
			end

			temp_file.flush
			temp_file
		end

		def download_file(part,remote_file,local_file)
			Chef::Log.debug("Saving file to #{local_file}")
			Chef::Log.info("Fetching file: #{remote_file} part: #{part['slot']} Start: #{part['start']} End: #{part['end']}")
			uri = URI(remote_file)

			ssl = uri.scheme == "https" ? true : false
			Net::HTTP.start(uri.host, uri.port,:use_ssl => ssl) do |http|
				request = Net::HTTP::Get.new uri
				Chef::Log.debug("Requesting slot: #{part['slot']} from #{part['start']} to #{part['end']}")
				request.add_field('Range', "bytes=#{part['start']}-#{part['end']}")

				http.request request do |response|
					open local_file, 'wb' do |io|
						response.read_body do |chunk|
							io.write chunk
						end
					end
				end
			end
		end

		def calculate_parts(content_length,parts=10,chunk_size=1048576)
			parts_details = []
			chunk_parts = content_length / chunk_size
		
			unless chunk_parts <= parts
				chunk_size = content_length / parts
				chunk_parts = parts
			end

			(0..chunk_parts).each do |n|
				current_size = ((n * chunk_size) + chunk_size) >= content_length ? content_length : (n * chunk_size) + chunk_size
				byte_start = (n * chunk_size == 0) ? 0 : (n * chunk_size) + 1 
				byte_end = (n * chunk_size == 0) ? (chunk_size * 1)  : current_size
				
				if n == chunk_parts
					byte_end = ''
				end
				parts_details.push({'slot' => n, 'start' => byte_start, 'end' => byte_end})
			end

			return parts_details
		end
	end
end

