class Comment < ActiveRecord::Base
  # object owned one
  belongs_to :article
end
