#!/usr/local/bin/run_ruby_script_in_rvm

#====================================================================
# AJPapps - Tumblr shortcuts creator Ruby ver.
# 
# Линда Кайе 2017. Посвящается Ариэль
#====================================================================
# 
# Этот скрипт создаёт HTML файл со ссылками на ваши блоги 
# на Тумблере. Потом полученный файл можно импортировать в избранное 
# броузера и экономить нервы и трафик, парой щелчков переходя 
# к нужным разделам в закладках, а не в постоянно меняющемся 
# и тормозящем интерфейсе сайта. Да, всё это можно сделать 
# и ручками, но автоматика всегда удобнее, особенно когда у вас 
# на одном логине десяток блогов.
# 
# Скрипт тестировался в Ruby 2.0.0 и выше.
# 
# Настройки
# ---------
# 
# Перед началом использования скрипта, необходимо создать файл 
# конфигурации. Для этого требуется запустить команду "tumblr" 
# (команда гема tumblr_client), выполнить инструкции, а после 
# завершения процесса аутентификации переместить новосозданный 
# файл ".tumblr" из домашнего каталога в каталог со скриптом.
# 
# ВНИМАНИЕ! Файл ".tumblr" содержит важные данные, которые позволят 
# злоумышленнику получить неограниченный доступ к вашим блогам. 
# Поэтому берегите его.
# 
# В случае возникновения ошибок проверки сертификата сервера 
# (например, в Windows XP), можно форсировать использование 
# незащищённого протокола HTTP. Для этого в файле ".tumblr" 
# найдите строку, начинающуюся на "api_scheme:" и измените её, чтобы 
# она выглядела так:
# 
# > api_scheme: http
# 
# Ограничения
# -----------
# 
# Из-за особенностей информации, получаемой от Tumblr API v2, этот 
# скрипт не может определить идентификаторы приватных блогов (они 
# просто не предоставляются). Поэтому ссылки на них работать 
# не будут.
# 
# Зависимости
# -----------
# 
# Для работы этого скрипта нужны следующие гемы:
# 
# • tumblr_client
# • unicode
# 
# Устанавливаются так:
# 
# > gem install tumblr_client
# > gem install unicode
# 
# История изменений
# -----------------
# 
# • 1.03.2017
#   Первая публичная версия ^^
# 
#====================================================================
# Маленький копирайт
# 
# 1. Программа и исходный код распространяются бесплатно.
# 2. Вы имеете право распространять их на тех же условиях.
# 3. Вы не имеете права использовать имя автора после модификации 
#    исходного кода.
# 4. При этом желательно указывать ссылку на автора оригинальной 
#    версии исходного кода.
# 5. Вы не имеете права на платное распространение исходного кода, 
#    а также программных модулей, содержащих данный исходный код.
# 6. Программа и исходный код распространяются как есть. Автор не 
#    несёт ответственности за любые трагедии или несчастные случаи, 
#    вызванные использованием программы и исходного кода.
# 7. Для любого пункта данного соглашения может быть сделано 
#    исключение с разрешения автора программы.
# 8. По любым вопросам, связанным с данной программой, обращайтесь 
#    по адресу lindaoneesama@gmail.com
# 
# Загружено с http://purl.oclc.org/Linda_Kaioh/Homepage/
#====================================================================

# Additional:
# https://github.com/tumblr/tumblr_client/blob/master/lib/tumblr/config.rb
# https://github.com/tumblr/tumblr_client/blob/master/lib/tumblr/post.rb

#====================================================================
require "tumblr_client"
require "unicode"
require "yaml"

# Для show_copyright()...
APP_TITLE = "AJPapps - Tumblr shortcuts creator Ruby ver."
APP_COPYRIGHT = "Линда Кайе 2017. Посвящается Ариэль"

DEF_HTML_FILE_NAME = "tumblr_shortcuts_creator.html"

LINK_PROTOCOL = "https"
LINK_BLOG_PART = "blog" # "tumblelog"

#=====================================================================
def show_copyright()
  puts APP_TITLE
  puts APP_COPYRIGHT
  puts
end

#=====================================================================
def show_usage()
  puts "Использование: #{ File.split($PROGRAM_NAME)[-1] } [html_file_name]"
  #puts
  #puts "Имя файла по умолчанию: #{ DEF_HTML_FILE_NAME }"
end

#====================================================================
def get_html_file_name()
  # Предполагаем ошибку...
  file_name = nil
  
  case ARGV.length
    when 0
      file_name = DEF_HTML_FILE_NAME
    when 1
      if ARGV[0] == "/?" then
        show_usage
      else
        file_name = ARGV[0]
      end
    else
      show_usage
  end
  
  return file_name
end

#====================================================================
def put_file(file_name, text)
  File.open(file_name, "w") do |stream|
    stream.write text
  end
end

#====================================================================
def get_file(file_name)
  txt = ""
  File.open(file_name, "r") do |stream|
    txt = stream.read()
  end
  return txt
end

#====================================================================
def make_tumblr_request()
  # Читаем конфиг в текущем каталоге...
  yaml_file_name = File.join(File.split($PROGRAM_NAME)[0], ".tumblr")
  yaml_text = get_file(yaml_file_name)
  yaml = YAML.load(yaml_text)
  
  # Set up common options...
  Tumblr.configure do |config|
    config.consumer_key       = yaml["consumer_key"]
    config.consumer_secret    = yaml["consumer_secret"]
    config.oauth_token        = yaml["oauth_token"]
    config.oauth_token_secret = yaml["oauth_token_secret"]
    config.client             = yaml["client"]
    config.api_scheme         = yaml["api_scheme"]
  end
  
  # Make new client instance...
  client = Tumblr::Client.new()
  info = client.info
  
  if info.has_key?("status") then
    if info["status"] == 200 then
      return info
    else
      # {"status"=>401, "msg"=>"Unauthorized"}
      raise "Tumblr returns: #{ info["status"] } #{ info["msg"] }"
    end
  else
    return info
  end
end

#====================================================================
def parse_groups(info)
  blogs = info["user"]["blogs"]
  tumblelogs = []
  
  blogs.each do |blog|
    tumblelog = {}
    
    tumblelog["title"]      = blog["title"]
    tumblelog["is_admin"]   = blog["admin"]
    tumblelog["name"]       = blog["name"]
    tumblelog["url"]        = blog["url"]
    tumblelog["is_private"] = (blog["type"] == "private")
    tumblelog["private_id"] = blog["private-id"]
    
    # Увы... Что-то API v2 идентификатор не возвращает, поэтому 
    # смотрим, есть ли таковой, и, если нет, то вставляем нули. 
    # Пусть хоть какие-то ссылки генерируются.
    # 
    # Переиграли! Никакие нули не ставим, а ниже проверяем, есть 
    # ли ID!
    #if tumblelog["is_private"] then
    #  if tumblelog["private_id"].nil? then
    #    tumblelog["private_id"] = "000000"
    #  end
    #end
    
    # Debug!
    #puts "#{ blog["title"] } :: #{ blog["messages"] }"
    
    # Будем пропускать приватные блоги, если у них нет 
    # идентификатора! 
    if tumblelog["is_private"] then
      if not tumblelog["private_id"].nil? then
        tumblelogs << tumblelog
      end
    else
      tumblelogs << tumblelog
    end
  end
  
  # Сортируем группы по заголовку... Что возвращает блок, по тому 
  # и сортируется, однако!
  tumblelogs.sort_by! do |tumblelog|
    Unicode::upcase(tumblelog["title"])
  end
  
  # Возвращаем полученное...
  return tumblelogs
end

#====================================================================
def build_links_tree(tumblelogs)
  # Это нам пригодится при создании HTML файла. 
  # А может и не пригодиься...
  root = { "title" => "Tumblr",
           "subgroups" => [],
           "links" => [] }
  
  tumblelogs.each do |tumblelog|
    subgroup = { "title" => tumblelog["title"],
                 "subgroups" => [],
                 "links" => [] }
    
    # Activity
    if not tumblelog["is_private"] and tumblelog["is_admin"] then
      link = { "title" => "Activity",
               "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/#{ LINK_BLOG_PART }/#{ tumblelog["name"] }/activity" }
      subgroup["links"] << link
    end
    
    # Customize
    if not tumblelog["is_private"] and tumblelog["is_admin"] then
      link = { "title" => "Customize",
               "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/customize/#{ tumblelog["name"] }" }
      subgroup["links"] << link
    end
    
    # Dashboard...
    link = { "title" => "Dashboard" }
    if tumblelog["is_private"] then
      link["url"] = "#{ LINK_PROTOCOL }://www.tumblr.com/#{ LINK_BLOG_PART }/private_#{ tumblelog["private_id"] }"
    else
      link["url"] = "#{ LINK_PROTOCOL }://www.tumblr.com/#{ LINK_BLOG_PART }/#{ tumblelog["name"] }"
    end
    subgroup["links"] << link
    
    # Settings
    if not tumblelog["is_private"] and tumblelog["is_admin"] then
      link = { "title" => "Settings",
               "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/#{ LINK_BLOG_PART }/#{ tumblelog["name"] }/settings" }
      subgroup["links"] << link
    end
    
    # Sumbissions
    if not tumblelog["is_private"] and tumblelog["is_admin"] then
      link = { "title" => "Submissions",
               "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/#{ LINK_BLOG_PART }/#{ tumblelog["name"] }/messages" }
      subgroup["links"] << link
    end
    
    # Web
    if not tumblelog["is_private"] then
      link = { "title" => "Web",
               "url" => tumblelog["url"] }
      subgroup["links"] << link
    end
    
    root["subgroups"] << subgroup
  end
  
  # Twitter - disabled now...
  #link = { "title" => "@Twitter",
  #         "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/twitter" }
  #root["links"] << link
  
  # Dashboard
  link = { "title" => "Dashboard",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/dashboard" }
  root["links"] << link
  
  # Goodies
  link = { "title" => "Goodies",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/goodies" }
  root["links"] << link
  
  # Inbox
  link = { "title" => "Inbox",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/inbox" }
  root["links"] << link
  
  # Log in...
  link = { "title" => "Log in...",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/login" }
  root["links"] << link
  
  # Preferences
  link = { "title" => "Preferences",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/preferences" }
  root["links"] << link
  
  # Tumblr API
  link = { "title" => "Tumblr API",
           "url" => "#{ LINK_PROTOCOL }://www.tumblr.com/docs/en/api" }
  root["links"] << link
  
  return root
end

#====================================================================
def get_html_file_header()
  return <<HEADER_END
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
HEADER_END
end

#====================================================================
def get_group_html(group, level)
  if group["subgroups"].length == 0 and group["links"].length == 0 then
    return ""
  end
  
  txt = ""
  pad = " " * (level * 4)
  
  txt += "#{ pad }<DT><H3>#{ group["title"] }</H3>\n" +
         "#{ pad }<DL><p>\n"
  
  group["subgroups"].each do |subgroup|
    txt += "#{ get_group_html(subgroup, level + 1) }\n"
  end
  
  group["links"].each do |link|
    txt += "#{ pad }    <DT><A HREF=\"#{ link["url"] }\">#{ link["title"] }</A>\n"
  end
  
  txt += "#{ pad }</DL><p>"
  return txt
end

#====================================================================
def create_html_file(links_root)
  return <<HTML_END
#{ get_html_file_header() }
<DL><p>
#{ get_group_html(links_root, 1) }
</DL><p>
HTML_END
end

#====================================================================
def main()
  # Обязательно ^^v
  show_copyright
  
  # Считаем, что всё хорошо...
  rc = 0
  
  begin
    # Сначала получаем имя файла...
    html_file_name = get_html_file_name()
    if html_file_name.nil? then
      return 1
    end
    
    # Make Tumblr request and get post ID...
    puts "Отправляем запрос к Tumblr..."
    info = make_tumblr_request()
    
    # Get groups...
    puts "Парсим информацию о блогах..."
    tumblelogs = parse_groups(info)
    
    # Get links...
    puts "Строим дерево ссылок..."
    links_root = build_links_tree(tumblelogs)
    
    # Make Mozilla HTML file...
    puts "Генерируем HTML файл для импорта..."
    html = create_html_file(links_root)
    
    # Save HTML to external file...
    puts "Сохраняем HTML файл: #{ html_file_name }"
    put_file html_file_name, html
    
    # All Ok!
    puts "Готово!"
  rescue Exception => e
    puts "Ошибка: [#{ e.class.to_s }] #{ e.message }"
    rc = 1
  end
  
  # Return exit code!
  return rc
end

#====================================================================
exit main()
