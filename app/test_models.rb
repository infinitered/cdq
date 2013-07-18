class Author < CDQManagedObject
end

class Article < CDQManagedObject
  scope :all_published, where(:published).eq(true)
  scope :with_title, where(:title).ne(nil).sort_by(:title, :descending)
  #scope :published_since { |date| all.where(value(:publishedAt) > date) }
end

class Citation < CDQManagedObject
end

class Writer < CDQManagedObject
end

