class Author < CDQManagedObject
end

class Article < CDQManagedObject
  scope :clashing, where(:title).eq('war & peace')
  scope :all_published, where(:published).eq(true)
  scope :with_title, where(:title).ne(nil).sort_by(:title, order: :descending)
  scope :published_since { |date| where(:publishedAt).ge(date) }
end

class Citation < CDQManagedObject
end

class Writer < CDQManagedObject
  scope :clashing, where(:fee).eq(42.0)
end

class Timestamp < CDQManagedObject
end

