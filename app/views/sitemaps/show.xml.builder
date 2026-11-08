xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [ root_url, how_it_works_url, new_contact_url, vendor_signup_url ].each do |url|
    xml.url { xml.loc url; xml.changefreq "weekly"; xml.priority(url == root_url ? "1.0" : "0.8") }
  end
  @occasions.each do |o|
    xml.url { xml.loc occasion_url(o); xml.lastmod o.updated_at.to_date.iso8601; xml.priority "0.9" }
  end
  @legal_pages.each do |p|
    xml.url { xml.loc legal_page_url(p); xml.lastmod p.updated_at.to_date.iso8601; xml.priority "0.3" }
  end
end
