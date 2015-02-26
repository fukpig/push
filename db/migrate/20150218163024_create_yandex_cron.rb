class CreateYandexCron < ActiveRecord::Migration
  def change
    create_table :yandex_crons do |t|
      t.string :domain
      t.string :email
    end
  end
end
