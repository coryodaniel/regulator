require "spec_helper"

describe Regulator do
  let(:user) { double }
  let(:params) { { :action => 'update' } }

  context 'when supplying a specific module namespace' do
    let(:song) { Song.new(user: user) }
    let(:policy){ Regulator.policy!(user, song, Api::V2) }

    it{ expect(policy).to be_kind_of(Api::V2::SongPolicy) }
  end

  context 'when the controller is namespaced multiple levels deep' do
    let(:song) { Song.new(user: user) }
    let(:controller){ Api::V2::SongsController.new(user, params) }

    describe '#policy' do
      let(:policy){ controller.policy(song) }
      it{ expect(policy).to be_kind_of(Api::V2::SongPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.song).to be song }
    end

    describe '#authorize' do
      it{ expect(controller.authorize(song)).to be true }
    end

    describe '#policy_namespace' do
      it{ expect(controller.policy_namespace).to be Api::V2 }
    end

    describe '#policy_scope' do
      let(:policy_scope){ controller.policy_scope(Song) }
      it{ expect(policy_scope).to be Song }
    end
  end

  context 'when the controller is not namespaced' do
    let(:controller){ ArtistsController.new(user, params) }
    let(:artist){ Artist.new(user: user) }
    describe '#policy' do
      let(:policy){ controller.policy(artist) }
      it{ expect(policy).to be_kind_of(ArtistPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.artist).to be artist }
    end

    describe '#authorize' do
      it{ expect(controller.authorize(artist)).to be true }
    end

    describe '#policy_namespace' do
      it{ expect(controller.policy_namespace).to be nil }
    end

    context 'when the model is namespaced' do
      let(:cool_comment){ CoolPlugin::Comment.new }
      describe '#policy' do
        let(:policy){ controller.policy(cool_comment) }
        it{ expect(policy).to be_kind_of(CoolPlugin::CommentPolicy) }
        it{ expect(policy.user).to be user }
        it{ expect(policy.comment).to be cool_comment }
      end

      describe '#policy_scope' do
        let(:policy_scope){ controller.policy_scope(CoolPlugin::Comment) }
        it{ expect(policy_scope).to be CoolPlugin::Comment }
      end
    end
  end

  context 'when the controller sets the policy_class' do
    let(:controller){ Api::AlbumsController.new(user, params) }
    let(:album){ Album.new }

    describe '#policy' do
      let(:policy){ controller.policy(album) }
      it{ expect(policy).to be_kind_of(MusicAlbumPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.album).to be album }
    end

    describe '#policy_scope' do
      let(:policy_scope){ controller.policy_scope(Album) }
      it{ expect(policy_scope).to be Album }
    end
  end

  context 'when the controller sets the policy_namespace' do
    let(:controller){ Api::PlaylistsController.new(user, params) }
    let(:playlist){ Playlist.new }

    describe '#policy' do
      let(:policy){ controller.policy(playlist) }
      it{ expect(policy).to be_kind_of(Legacy::PlaylistPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.playlist).to be playlist }
    end

    describe '#policy_namespace' do
      it{ expect(controller.policy_namespace).to be(Legacy) }
    end
  end

  context 'when the controller explicitly sets the policy_namespace to nil' do
    let(:controller){ Api::PlaylistsController.new(user, params) }
    let(:playlist){ Playlist.new }

    before do
      Api::PlaylistsController.class_eval do
        def self.policy_namespace
          nil
        end
      end
    end

    describe '#policy' do
      let(:policy){ controller.policy(playlist) }
      it{ expect(policy).to be_kind_of(PlaylistPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.playlist).to be playlist }
    end

    describe '#policy_namespace' do
      it{ expect(controller.policy_namespace).to be(nil) }
    end
  end

  context 'when the controller is namespaced' do
    let(:controller){ Api::ArtistsController.new(user, params) }
    let(:artist) { Artist.new(user: user) }

    describe '#policy' do
      let(:policy){ controller.policy(artist) }
      it{ expect(policy).to be_kind_of(Api::ArtistPolicy) }
      it{ expect(policy.user).to be user }
      it{ expect(policy.artist).to be artist }
    end

    describe '#authorize' do
      it{ expect(controller.authorize(artist)).to be true }
    end

    describe '#policy_namespace' do
      it{ expect(controller.policy_namespace).to be Api }
    end

    context 'when the model is namespaced' do
      let(:cool_comment){ CoolPlugin::Comment.new }

      describe '#policy' do
        let(:policy){ controller.policy(cool_comment) }
        it{ expect(policy).to be_kind_of(Api::CoolPlugin::CommentPolicy) }
        it{ expect(policy.user).to be user }
        it{ expect(policy.comment).to be cool_comment }
      end

      describe '#policy_scope' do
        let(:policy_scope){ controller.policy_scope(CoolPlugin::Comment) }
        it{ expect(policy_scope).to be CoolPlugin::Comment }
      end

      describe '#policy_namespace' do
        it{ expect(controller.policy_namespace).to be Api }
      end
    end

    describe "#verify_authorized" do
      it "does nothing when authorized" do
        controller.authorize(artist)
        controller.verify_authorized
      end

      it "raises an exception when not authorized" do
        expect { controller.verify_authorized }.to raise_error(Regulator::AuthorizationNotPerformedError)
      end
    end

    describe "#verify_policy_scoped" do
      it "does nothing when policy_scope is used" do
        controller.policy_scope(Artist)
        controller.verify_policy_scoped
      end

      it "raises an exception when policy_scope is not used" do
        expect { controller.verify_policy_scoped }.to raise_error(Regulator::PolicyScopingNotPerformedError)
      end
    end

    describe "#regulator_policy_authorized?" do
      it "is true when authorized" do
        controller.authorize(artist)
        expect(controller.regulator_policy_authorized?).to be true
      end

      it "is false when not authorized" do
        expect(controller.regulator_policy_authorized?).to be false
      end
    end

    describe "#regulator_policy_scoped?" do
      it "is true when policy_scope is used" do
        controller.policy_scope(Artist)
        expect(controller.regulator_policy_scoped?).to be true
      end

      it "is false when policy scope is not used" do
        expect(controller.regulator_policy_scoped?).to be false
      end
    end

    describe "#authorize" do
      it "infers the policy name and authorizes based on it" do
        expect(controller.authorize(artist)).to be_truthy
      end

      it "can be given a different permission to check" do
        expect(controller.authorize(artist, :show?)).to be_truthy
        expect { controller.authorize(artist, :destroy?) }.to raise_error(Regulator::NotAuthorizedError)
      end

      it "throws an exception when the permission check fails" do
        expect { controller.authorize(Artist.new) }.to raise_error(Regulator::NotAuthorizedError)
      end

      it "throws an exception when a policy cannot be found" do
        expect { controller.authorize(Article) }.to raise_error(Regulator::NotDefinedError)
      end

      it "caches the policy" do
        expect(controller.policies[artist]).to be_nil
        controller.authorize(artist)
        expect(controller.policies[artist]).not_to be_nil
      end

      it "raises an error when the given record is nil" do
        expect { controller.authorize(nil, :destroy?) }.to raise_error(Regulator::NotDefinedError)
      end
    end

    describe "#skip_authorization" do
      it "disables authorization verification" do
        controller.skip_authorization
        expect { controller.verify_authorized }.not_to raise_error
      end
    end

    describe "#skip_policy_scope" do
      it "disables policy scope verification" do
        controller.skip_policy_scope
        expect { controller.verify_policy_scoped }.not_to raise_error
      end
    end

    describe "#regulator_user" do
      it 'returns the same thing as current_user' do
        expect(controller.regulator_user).to eq controller.current_user
      end
    end

    describe "#policy" do
      let(:manager){ Manager.new }

      it "returns an instantiated policy" do
        policy = controller.policy(artist)
        expect(policy.user).to eq user
        expect(policy.artist).to eq artist
      end

      it "throws an exception if the given policy can't be found" do
        expect { controller.policy(manager) }.to raise_error(Regulator::NotDefinedError)
      end

      it "allows policy to be injected" do
        new_policy = OpenStruct.new
        controller.policies[artist] = new_policy

        expect(controller.policy(artist)).to eq new_policy
      end
    end

    describe "#policy_scope" do
      it "returns an instantiated policy scope" do
        expect(controller.policy_scope(Artist)).to eq :published
      end

      it "throws an exception if the given policy can't be found" do
        expect { controller.policy_scope(Article) }.to raise_error(Regulator::NotDefinedError)
      end

      it "allows policy_scope to be injected" do
        new_scope = OpenStruct.new
        controller.policy_scopes[Artist] = new_scope

        expect(controller.policy_scope(Artist)).to eq new_scope
      end
    end

    describe "#permitted_attributes" do
      let(:params){
        ActionController::Parameters.new({ action: 'update', artist: { title: 'Hello', songs: 5, free_download: true } })
      }
      let(:controller){ Api::ArtistsController.new(user, params) }
      let(:promoter){ double }
      let(:restricted_controller){ Api::ArtistsController.new(promoter, params)}

      it "checks policy for permitted attributes" do
        expect(controller.permitted_attributes(artist)).to eq({ 'title' => 'Hello', 'songs' => 5 })
        expect(restricted_controller.permitted_attributes(artist)).to eq({ 'free_download' => true })
      end
    end
  end
end
