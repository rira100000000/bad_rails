# [BAD-090]
puts "Seeding..."

Notification.delete_all
Favorite.delete_all
Review.delete_all
Order.delete_all
Book.delete_all
Category.delete_all
User.delete_all

cats = ["技術書", "小説", "ビジネス", "漫画", "雑誌"].map { |n| Category.create!(name: n) }

alice = User.create!(name: "Alice",  email: "alice@example.com",  password: "password", address: "Tokyo", phone: "090-0000-0001", point: 500)
bob   = User.create!(name: "Bob",    email: "bob@example.com",    password: "password", address: "Osaka", phone: "090-0000-0002", point: 0)
carol = User.create!(name: "Carol",  email: "carol@example.com",  password: "password", address: "Kyoto", phone: "090-0000-0003", point: 1200)
dave  = User.create!(name: "Dave",   email: "dave@example.com",   password: "password", address: "Nagoya", phone: "090-0000-0004", point: 100)

15.times do |i|
  Book.create!(
    title:       "サンプル書籍 #{i + 1}",
    author:      ["山田太郎", "佐藤花子", "Matz", "DHH"].sample,
    description: "状態は良好です。書き込みなし。",
    price:       [500, 800, 1200, 1500, 2000, 3500].sample,
    status:      "listed",
    condition:   ["新品同様", "良い", "普通", "やや傷あり"].sample,
    isbn:        "978-4-1234-5678-#{i}",
    seller:      [alice, bob, carol, dave].sample,
    category:    cats.sample
  )
end

puts "Done. Users: #{User.count}, Books: #{Book.count}"
