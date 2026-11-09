# Royalty-free Unsplash photography used as defaults on the public site.
# Any image uploaded to a Product in the admin always takes precedence.
module StockImagesHelper
  UNSPLASH = {
    # categories
    "chocolates" => "1481391319762-47dff72954d9", "cups-mugs" => "1604423043492-41303788de80",
    "earphones" => "1505740420928-5e560c06d30e", "bags" => "1553062407-98eeb64c6a62",
    "greeting-cards" => "1513201099705-a9746e1e201f", "organic-sweets" => "1599599810769-bcde5a160d32",
    "paintings" => "1579783902614-a3fb3927b6a5", "diaries" => "1517842645767-c639042777db",
    "bottles" => "1602143407151-7111542de6e8", "t-shirts" => "1521572163474-6864f9cf17ab",
    "dry-fruits" => "1508061253366-f7da158b6d46", "decor" => "1605292356183-a77d0a9c9d1d",
    # occasions & use cases
    "diwali" => "1605292356183-a77d0a9c9d1d", "new-year" => "1467810563316-b5476525c0f9",
    "birthday" => "1530103862676-de8c9debad1d", "onboarding" => "1497032628192-86f99bcd76bc",
    "festival" => "1513885535751-8b9238bd345a", "rewards" => "1600880292203-757bb62b4baf",
    "clients" => "1521791136064-7986c2920216", "team" => "1522071820081-009f0129c71c",
    "events" => "1556761175-5973dc0f32e7", "milestones" => "1606800052052-a08af7148866",
    # hero / mood
    "hero-luxe" => "1608755728617-aefab37d2edd", "hero-gold" => "1607344645866-009c320b63e0",
    "hero-pink" => "1549465220-1a8b9238cd48", "hero-hands" => "1512909006721-3d6018887383",
    "tote" => "1590874103328-eac38a683ce7", "hoodie" => "1556821840-3a63f95609a7", "coffee" => "1604423043492-41303788de80"
  }.freeze

  def stock_image_url(key, w: 800, h: nil)
    id = UNSPLASH.fetch(key.to_s) { UNSPLASH["hero-gold"] }
    "https://images.unsplash.com/photo-#{id}?auto=format&fit=crop&w=#{w}#{"&h=#{h}" if h}&q=70"
  end

  def product_image_url(product, w: 600)
    return url_for(product.images.first) if product.images.attached?
    stock_image_url(product.category&.slug, w:, h: w)
  end
end
