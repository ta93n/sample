class Post < ApplicationRecord
  belongs_to :user # ユーザーと１対１の関係
  has_many :likes, dependent: :destroy
  has_many :like_users, through: :likes, source: :user
  has_many :comments, dependent: :destroy
  has_many :post_genre_relations, dependent: :destroy
  has_many :genres, through: :post_genre_relations
  scope :recent, -> { order(created_at: :desc) } # データベースから要素を取得したときの順序を指定する。created_atカラムの順にしたい場合の設定
  mount_uploader :picture, PictureUploader # CarrierWaveに画像と関連付けたPostモデルを伝える。引数は属性名のシンボルとアップローダーのクラス名
  validates :user_id, presence: true
  validates :shop_name, presence: true, length: { maximum: 20 }
  validates :nearest, presence: true, length: { maximum: 20 }
  validates :content, length: { maximum: 1000 }
  validate  :picture_size # validateは引数にシンボルを取り、そのシンボル名に対応したメソッドを呼び出す
  before_save :geocode

  # ポストをlikeする
  def like(user)
    likes.create(user_id: user.id)
  end

  # ポストのlikeを解除する
  def unlike(user)
    likes.find_by(user_id: user.id).destroy
  end

  # 現在のユーザーがlikeしてたらtrueを返す
  def like?(user)
    like_users.include?(user)
  end

  private

    # アップロードされた画像のサイズをバリデーションする (ファイルサイズに対するバリデーションはRailsの既存のオプションには無い)
    def picture_size
      if picture.size > 5.megabytes
        errors.add(:picture, "画像は5MBより小さくしてください。")
      end
    end

    # バリデーションの後にgeocordingAPIを使って店名と最寄駅情報から緯度経度を取得、緯度経度カラムに保存する
    def geocode
      uri = URI.escape("https://maps.googleapis.com/maps/api/geocode/json?address=" + self.shop_name + " " + self.nearest +
                       "&key=" + Rails.application.credentials.GCP[:API_KEY])
      res = HTTP.get(uri).to_s
      response = JSON.parse(res)
      if response["status"] == "OK"
        self.latitude = response["results"][0]["geometry"]["location"]["lat"]
        self.longitude = response["results"][0]["geometry"]["location"]["lng"]
      else
        self.latitude = 1
        self.longitude = 1
      end
    end
end
