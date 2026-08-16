class CreateShortenedUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :shortened_urls do |t|
      t.text :original_url, null: false
      t.string :short_code, null: false, limit: 16

      t.timestamps
    end

    add_index :shortened_urls, :short_code, unique: true
  end
end