#!/usr/bin/env ruby

require 'json'
require 'haml'
require 'chronic'

module Dirt

  class TableMacro < Macro
    def to_html
      sql = @spec['sql']
      rows = Dirt::RT_DB[sql].all

      # TODO: Handle the no results case
      rows = [{"result" => "No rows to display"}] if rows.count == 0

      headers = rows.first.keys
      
      caption = @spec['caption'] 
      caption ||= ""

      haml :table, binding
    end    
  end

end
