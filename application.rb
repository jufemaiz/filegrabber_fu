require 'rubygems'
require 'sinatra'
require 'fileutils'
require 'open-uri'
require 'zip/zip'

require 'haml'
  set :haml, :format => :html5
require 'sass'
require 'coffee-script'
require 'partials'

# ----------------------------------
# Prepare params
# ----------------------------------

before do
  params[:query] = get_params
end


# ----------------------------------
# Homepage
# ----------------------------------

get '/' do
  haml :index
end

# ----------------------------------
# Put File
# ----------------------------------
post '/' do
  
  @file = nil
  if !params[:file_location].nil?
    original_file             = { :location => params[:file_location] }
    original_file[:name]      = params[:file_location].split(/\//).last
    original_file[:directory] = original_file[:location][0..(original_file[:location].length - original_file[:name].length - 1)]

    filestream = open(original_file[:location]).read
    
    t = Tempfile.new("my-temp-filename-#{Time.now}")
    Zip::ZipOutputStream.open(t.path) do |z|
      z.put_next_entry("#{original_file[:name]}.jpg")
      z.print filestream
    end
    send_file t.path, :type => 'application/zip',
                      :disposition => 'attachment',
                      :filename => "#{original_file[:name]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.jpg"
    t.close    
    @file = { :location => "http://files.euphemize.net/download/#{original_file[:name]}", :original => original_file, :filestream => filestream }
  end
  
  @params = params
  
  haml :index
end

# ----------------------------------
# SCSS Custom Styling
# ----------------------------------

get '/css/app.css' do
  sass :app
end

get %r{^(\/js\/[a-zA-Z0-9_\/\-\.]+\.coffee)\.js} do |filename|
  content_type :js
  puts options.public + filename
  base_name = options.public + filename
  if File.exists? base_name
    CoffeeScript.compile File.open(base_name, 'r'){|f| f.read }
  else
    File.open(base_name + '.js', 'r'){|f| f.read }
  end
end

# 
# Helpers
# 

helpers Sinatra::Partials
helpers do
  
  def commify(number)
    if number.to_s.match(/^\d*(\.(\d+)?)?/)
      number = number.to_s.gsub(/(\d)(?=(\d{3})+$)/,'\1,')
    end
    number
  end
  
  def get_params
    params = {}
    request.query_string.split('&').each do |q|
      params[q.split('=')[0]] = q.split('=')[1].split('+')
    end
    return params
  end
  
end