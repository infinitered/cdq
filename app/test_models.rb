class Author < CDQManagedObject
end

class Article < CDQManagedObject
  scope :all_published, where(:published).eq(true)
  scope :with_title, where(:title).ne(nil).sort_by(:title, order: :descending)
  scope :published_since { |date| where(:publishedAt).ge(date) }
end

class Citation < CDQManagedObject
end

class Writer < CDQManagedObject
end

class Timestamp < CDQManagedObject
end

