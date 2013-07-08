class Author < CDQ::CDQManagedObject
end

class Article < CDQ::CDQManagedObject
  #scope :all_published, where(:published => true)
  scope :all_published, where(:published).eq(true)
  scope :with_title, where(:title).ne(nil).sort_by(:title, :descending)
  #scope :published_since { |date| all.where(value(:publishedAt) > date) }
end

class Writer < CDQ::CDQManagedObject
end

