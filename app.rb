#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

before do
	init_db
end

configure do
	init_db
	# создаёт таблицу, если не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts
		(
			id	INTEGER,
			created_date	TEXT,
			content	TEXT,
			PRIMARY KEY(id AUTOINCREMENT)
		)'
	# создаёт таблицу, если не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
		(
			id	INTEGER,
			created_date	TEXT,
			content	TEXT,
			post_id	INTEGER,
			PRIMARY KEY(id AUTOINCREMENT)
		)'
end

get '/' do
	# Выбираем список постов из БД

	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]

	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end

	# Сохранение записей в Базу данных

	@db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]

	# перенаправление на главную страницу
	redirect to '/'
end

# Вывод информации о посте

get '/details/:post_id' do

	# получаем переменную из url

	post_id = params[:post_id]

	# получаем список постов
	# у нас будет только один пост

	results = @db.execute 'select * from Posts where id = ?', [post_id]

	# Выбираем этот один пост в переменную @row

	@row = results[0]

	# выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# Возвращаем представление details.erb

	erb :details
end

# Обработчик пост запроса details
# браузер отправляет данные на сервер, а мы их принимаем

post '/details/:post_id' do

	# получаем переменную из url

	post_id = params[:post_id]

	# получаем переменную из пост-запроса

	content = params[:content]

	# Сохранение записей в Базу данных

	@db.execute 'insert into Comments
	(content, created_date, post_id) values (?, datetime(), ?)', [content, post_id]

	# перенаправление на страницу поста
	redirect to('/details/' + post_id)
end