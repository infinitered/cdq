
schema "0.0.1" do

  entity "Article" do

    string    :body,        optional: false
    integer32 :length
    boolean   :published,   default: false
    datetime  :publishedAt, default: false
    string    :title,       optional: false
    string    :title2

    belongs_to   :author
    has_many :citations
  end

  entity "Author" do
    string :name, optional: false
    float :fee
    has_many :articles
  end

  entity "Writer" do
    string :name, optional: false
    float :fee

    has_many :spouses, inverse: "Spouse.writers", ordered: true
  end

  entity "Spouse", class_name: "CDQManagedObject" do
    string :name, optional: true
    has_many :writers, inverse: "Writer.spouses"
  end

  entity "Publisher", class_name: "CDQManagedObject" do
    string :name, optional: false
  end

  entity "Citation" do
    string     :journal
    datetime   :timestamp
    belongs_to :article
  end
  
  entity "Timestamp" do
    boolean   :flag
    datetime  :created_at
    datetime  :updated_at
  end

end
