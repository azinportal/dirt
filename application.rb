#!/usr/bin/env ruby

require 'mysql2'
require 'sequel'
require 'sinatra'
require 'haml'
require 'pp'
require 'logger'
require 'yaml'
use Rack::Logger 

module Dirt

  class Controller
    def self.show(params)
      controller = self.new
      controller.show(params)
    end 

    def self.edit(params)
      controller = self.new
      controller.edit(params)
    end 

    def haml( template_id )
      layout = File.read('views/layout.haml')
      template = File.read('views/' + template_id.to_s + '.haml')
      layout_engine = Haml::Engine.new(layout)
      layout_engine.render(self) do
        template_engine = Haml::Engine.new(template)
        template_engine.render(self)
      end
    end
  end 

  class PageController < Dirt::Controller
    def show(params)
      @project = params[:project]
      @page_name = params[:page]
      @page = Dirt::Page.html(@project, @page_name)
      haml :page
    end

    def edit(params)
      @project = params[:project]
      @page_name = params[:page]
      @page = Dirt::Page.source(@project, @page_name)
      haml :page_edit
    end

    def save(params)

    end 
  end

  class CardWallController < Dirt::Controller
    def show(params)
      @cards = Hash.new
      @queue = params[:queue]
      @statuses = [ 'new', 'open', 'stalled', 'resolved' ]
      # @results = Ticket.all(:queue => @queue, :status => @statuses)
      queue = Dirt::Queue[:name => @queue]

      @statuses.each do |status|
        @cards[status] = Dirt::Ticket.eager_graph(:owner).where(:status => status, :queue => queue).all
        # @cards[status] = queue.ticket(:status => status)
      end

      haml :card_wall
    end
  end

  class Application < Sinatra::Application
    CONFIG_FILE = File.join(File.dirname(__FILE__), 'config/config.yml')
    DB_CONFIG_FILE = File.join(File.dirname(__FILE__), 'config/database.yml')

    def self.load_config(file_name)
      env = ENV["RACK_ENV"]
      data = YAML::load(File.open(file_name))[env]
      data.inject({}) { |memo, (k,v)| memo[k.to_sym] = v; memo }
    end

    configure do
      # @config = load_config(CONFIG_FILE)
      db_config = load_config(DB_CONFIG_FILE)

      Dirt::RT_DB = Sequel.connect(db_config[:rt])
      Dirt::RT_DB.loggers << Logger.new($stdout)

      Dirt::DIRT_DB = Sequel.connect(db_config[:dirt])
      Dirt::DIRT_DB.loggers << Logger.new($stdout)

      Dir['models/*.rb'].each { |model| require File.join(File.dirname(__FILE__), model) }
    end


    get '/:queue' do
      Dirt::CardWallController.show(params)
    end

    get '/projects/:project/pages' do
      params[:page] = 'index'
      Dirt::PageController.show(params)
    end

    get '/projects/:project/pages/:page' do
      Dirt::PageController.show(params)
    end    

    get '/projects/:project/pages/:page/edit' do
      Dirt::PageController.edit(params)
    end    

    post '/projects/:project/pages/:page/save' do
      Dirt::PageController.save(params)
    end    


    run! if app_file == $0
  end

end

