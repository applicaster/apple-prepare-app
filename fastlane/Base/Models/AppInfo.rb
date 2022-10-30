# frozen_string_literal: true

class AppInfo
   attr_accessor :name, :bundle_identifier, :team_id, :platforms, :language, :version, :index

    def initialize(name, bundle_identifier, team_id)
       @name = name
       @bundle_identifier = bundle_identifier
       @team_id = team_id
       @platforms = ['ios', 'tvos']
       @language = "en-US"
       @version = "1.0"
       @index = "1"
    end
 end