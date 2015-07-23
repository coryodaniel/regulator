require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "pundit_compatibility_helper"

# set up models
module CoolPlugin
  class Comment; extend ActiveModel::Naming; end
end

class User; extend ActiveModel::Naming; end
class Album; extend ActiveModel::Naming; end
class Playlist; extend ActiveModel::Naming; end
class Manager; extend ActiveModel::Naming; end

class Song
  attr_accessor :user
  def initialize(user: nil)
    @user = user
  end
  extend ActiveModel::Naming
end

class Artist
  attr_accessor :user
  def initialize(user: nil)
    @user = user
  end
  extend ActiveModel::Naming

  def self.published
    :published
  end
end

# set up modules
module Api
  module V2
  end
end

# set up policies
class ArtistPolicy < Struct.new(:user, :artist)
  def update?
    artist.user == user
  end
  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end
end

class Api::V2::SongPolicy < Struct.new(:user, :song)
  def update?
    song.user == user
  end
  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end
end

class Api::ArtistPolicy < Struct.new(:user, :artist)
  def update?
    artist.user == user
  end
  def show?
    true
  end
  def destroy?
    false
  end
  def permitted_attributes
    if artist.user == user
      [:title, :songs]
    else
      [:free_download]
    end
  end
  class Scope < Struct.new(:user, :scope)
    def resolve
      scope.published
    end
  end
end

class MusicAlbumPolicy < Struct.new(:user, :album); end
class MusicAlbumPolicy::Scope < Struct.new(:user, :scope)
  def resolve
    scope
  end
end

class CoolPlugin::CommentPolicy < Struct.new(:user, :comment); end
class CoolPlugin::CommentPolicy::Scope < Struct.new(:user, :scope)
  def resolve
    scope
  end
end

module Api
  module CoolPlugin
    class CommentPolicy < Struct.new(:user, :comment); end
    class CommentPolicy::Scope < Struct.new(:user, :scope)
      def resolve
        scope
      end
    end
  end
end

module Legacy
  class PlaylistPolicy < Struct.new(:user, :playlist)
    class Scope < Struct.new(:user, :scope)
      def resolve
        scope
      end
    end
  end
end

# set up controllers
module Api
  class BaseController
    include Regulator

    attr_reader :current_user, :params

    def initialize(current_user, params)
      @current_user = current_user
      @params = params
    end
  end

  module V2
    class SongsController < Api::BaseController
    end
  end

  class ArtistsController < BaseController
  end

  class AlbumsController < BaseController
    def self.policy_class
      MusicAlbumPolicy
    end
  end

  class PlaylistsController < BaseController
    def self.policy_namespace
      Legacy
    end
  end

  # Endpoint to add a 'CoolPlugin::Comment'
  class CommentsController < BaseController
  end
end

# Front end, view comments
class CommentsController
  include Regulator

  attr_reader :current_user, :params

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end
end

# Front end, view artists
class ArtistsController
  include Regulator

  attr_reader :current_user, :params

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end
end
