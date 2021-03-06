require 'rails_helper'

RSpec.describe "user_model", type: :model do
  before do
    @user = FactoryBot.create(:user)
  end

  it "ユーザーmichaelが有効であること" do
    expect(@user).to be_valid
  end

  it "nameが空白のユーザーは無効であること" do
    @user.name = "     "
    expect(@user).to be_invalid
  end

  it "emailが空白のユーザーは無効であること" do
    @user.email = "     "
    expect(@user).to be_invalid
  end

  it "nameは16文字以内であること" do
    @user.name = "a" * 17
    expect(@user).to be_invalid
  end

  it "emailは255字以内であること" do
    @user.email = "a" * 244 + "@example.com"
    expect(@user).to be_invalid
  end

  it "有効なemailアドレスを受け付けること" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      expect(@user).to be_valid
    end
  end

  it "無効なemailアドレスを受け付けないこと" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com foo@bar..com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      expect(@user).to be_invalid
    end
  end

  it "emailは一意であること" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    expect(duplicate_user).to be_invalid
  end

  it "passwordが空白のユーザーは無効であること" do
    @user.password = @user.password_confirmation = " " * 6
    expect(@user).to be_invalid
  end

  it "passwordは6文字以上であること" do
    @user.password = @user.password_confirmation = "a" * 5
    expect(@user).to be_invalid
  end

  it "authenticated? should return false for a user with nil digest" do
    expect(@user.authenticated?(:remember, '')).to eq false
  end

  it "ユーザーが削除されるとユーザーの投稿も削除されること" do
    @post = FactoryBot.create(:post, user: @user)
    expect(@user.posts.count).to eq 1
    @user.destroy
    expect(@user.posts.count).to eq 0
  end

  describe "ユーザーのフォローとフォロー解除について" do
    before do
      @michael = FactoryBot.create(:user, name: "michael", email: "michael@example.com")
      @archer  = FactoryBot.create(:user, name: "archer", email: "archerl@example.com")
    end
    it "フォロー" do
      expect(@michael.following).not_to include(@archer)
      @michael.follow(@archer)
      expect(@michael.following).to include(@archer)
      expect(@archer.followers).to include(@michael)
    end
    it "フォロー解除" do
      @michael.active_relationships.create(followed_id: @archer.id)
      expect(@michael.following).to include(@archer)
      @michael.unfollow(@archer)
      expect(@michael.following).not_to include(@archer)
    end
  end

  describe "投稿について" do
    before do
      @michael = FactoryBot.create(:user, name: "michael", email: "michael@example.com")
      @archer  = FactoryBot.create(:user, name: "archer", email: "archerl@example.com")
      @lana    = FactoryBot.create(:user, name: "lana", email: "lana@example.com")
      @michael.follow(@lana)
    end
    it "フォローしているユーザーの投稿はフィードに表示されること" do
      @post = FactoryBot.create(:post, user: @lana)
      @lana.posts.each do |post_following|
        expect(@michael.feed).to include(post_following)
      end
    end
    it "自分自身の投稿はフィードに表示されること" do
      @post = FactoryBot.create(:post, user: @michael)
      @michael.posts.each do |post_self|
        expect(@michael.feed).to include(post_self)
      end
    end
    it "フォローしていないユーザーの投稿はフィードに表示されないこと" do
      @post = FactoryBot.create(:post, user: @archer)
      @archer.posts.each do |post_unfollowed|
        expect(@michael.feed).not_to include(post_unfollowed)
      end
    end
  end
end
