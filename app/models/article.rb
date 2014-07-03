class Article < ActiveRecord::Base
  # owner has many comment
  # If delete an article, its associated comments will be deleted
  has_many :comments, dependent: :destroy
  validates :title, presence: true, length: { minimum: 5 }
end
