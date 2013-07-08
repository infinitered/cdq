
schema "0.0.1" do

  entity "Article" do

    string    :body,        optional: false
    integer32 :length
    boolean   :published,   default: false
    datetime  :publishedAt, default: false
    string    :title,       optional: false

    belongs_to   :author
  end

  entity "Author" do
    string :name, optional: false
    float :fee
    has_many :articles 
  end

  entity "Writer" do
    string :name, optional: false
    float :fee
  end

  entity "Publisher" do # No class for this one
    string :name, optional: false
  end

end
