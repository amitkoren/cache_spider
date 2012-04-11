#coding: utf-8
require 'nokogiri'
require 'open-uri'

# ��Ҫץȡ�ĵ�ַ��������http
@my_url = "rubyer.me"
# ���п���Դ���ŵ�·��
@path = "./rubyer_cache"


def log(str)
  File.open("info.txt", "w+") {|f| f.puts str}
end

BAIDU_CACHE_URL = "http://www.baidu.com/s?wd=site:%s"
BAIDU_CACHE_PAGE_URL = "http://www.baidu.com/s?wd=site:%s?&pn=%d"

# ����url�õ���ҳԴ��
def get_source(url)
  #sleep for a while or baidu will block you
  log "sleep for:" + sleep(rand 5).to_s
  begin
    html = open(url).read
    html.force_encoding("gbk")
    html.encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace)
    Nokogiri::HTML.parse html
  rescue Exception => e
    puts "Error url: #{url}"
    puts e.message
    puts e.backtrace.inspect
  end
end

# ץȡ��page_numҳ��Դ��
def get_source_of_baidu_page(page_num)
  url = BAIDU_CACHE_PAGE_URL % [@my_url, page_num]
  get_source(url)
end

# �Ӱٶȿ���Դ���ȡ�����õ���Ϣ����ʵ�����ԭʼ��վԴ��
def get_cache(source_html)
  if source_html && source_html.xpath("/html/body/div[3]")[0]
    source_html.xpath("/html/body/div[3]")[0].inner_html
  else
    #��һЩҳ����սṹ�����⣬��������ֹ�����
    log "===============get cache error occurs next==================================="
    log source_html
    log "===============get cache error occurs above=================================="
  end
end

# ��ȡ�ٶȿ��յ�����ҳ��
def get_all_baidu_cache_pages
  doc = get_source(BAIDU_CACHE_URL % @my_url)
  total_num = doc.css(".site_tip strong")[0].content.scan(/\d+/)[0].to_i
  pages = []
  pages << doc.css("#container .result")
  i = 1
  while i*10 < total_num do
    doc = get_source_of_baidu_page(i*10)
    pages << doc.css("#container .result")
    i += 1
  end

  log "Get Pages Num: #{pages.size}"
  log "Get Items Num: #{total_num}"

  pages
end

# �õ�����ҳ�����Ŀ��һ���������Ϊһ����Ŀ(node)��
def get_nodes_of_pages(pages)
  nodes = []
  pages.each do |page|
    page.each do |item|
      origin_url = item.css(".f font .g")[0].content.to_s.strip
      origin_url = origin_url.split[0]
      origin_path = origin_url.gsub(/rubyer\.me/, '')
      origin_url = "http://" + origin_url
      nodes << {:origin_url => origin_url, :cache_url => item.css(".f font a")[0]["href"].to_s.strip, :origin_path => origin_path }
    end
  end
  nodes
end

# ����ÿһ����Ŀ���������ӦĿ¼���ļ������浽Ӳ����
def write_cache_to_disk(nodes)
  nodes.each do |node| 
    log "origin_url = #{node[:origin_url]}"
    log "cache_url  = #{node[:cache_url]}"
    log "origin_path = #{node[:origin_path]}"

    #ԭʼ��ַΪ"/"˵������ҳ�����ָ�Ϊindex
    file_name = node[:origin_path].split("?")[0]
    #file_name = file_name == "/" ? "#{@path}/index" : @path + node[:origin_path]
    file_name = @path + file_name + "/index.html"
    #file_name = file_name + ".html"

    #make dir
    dir = File.dirname(file_name)
    FileUtils.mkdir_p(dir) unless File.exists?(dir)

    log "file_name=#{file_name}"

    #create a file and write the html
    #`wget -O "#{file_name}" #{node[:cache_url]}`
    File.open(file_name, "w") do |file|
      file.puts get_cache(get_source(node[:cache_url]))
    end
  end
end

pages = get_all_baidu_cache_pages
nodes = get_nodes_of_pages(pages)
write_cache_to_disk(nodes)
