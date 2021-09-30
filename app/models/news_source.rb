class NewsSource < ApplicationRecord
  scope :active, -> {where(:enabled=>true)}
end
