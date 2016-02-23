require 'rails_helper'

describe 'Restaurants API' do
  describe 'GET /restaurants' do
    before { Restaurant.delete_all }

    let(:user) { User.create!(name: 'Hachiko', password: 'password') }
    let!(:tsukemen) { Restaurant.create!(name: "Tukemen TETSU", created_at: 2.days.ago, user: user) }
    let!(:curry) { Restaurant.create!(name: "Coco Curry", created_at: Time.now, user: user) }

    it 'returns all restaurants' do
      get '/restaurants', format: :json

      expect(json_response.count).to eq 2
      expect(json_response[0]['name']).to eq "Coco Curry"
      expect(json_response[1]['name']).to eq "Tukemen TETSU"
      expect(json_response[0]['user']['name']).to eq "Hachiko"
      expect(json_response[0]['created_at']).to eq curry.created_at.to_i
    end
  end

  describe 'POST /restaurants' do
    let(:restaurant_json) do
      {restaurant: {
          name: 'Tetsu',
          address: 'Roppongi',
          cuisine_type: 'Tonkatsu',
          offers_english_menu: true,
          walk_ins_ok: true,
          accepts_credit_cards: true,
          notes: 'This restaurant has tasty バーニャカウダ',
          photo_urls: [{url: 'http://tsukemen.com/noodle.jpg'}, {url: 'http://afuri.com/ramen.jpg'}]
      }}
    end
    let(:user) { User.create!(name: 'Hachiko', password: 'password') }
    let(:token) { TokenEncoder.new(user).token }

    it 'creates the restaurant' do
      expect {
        post '/restaurants', restaurant_json, {format: :json, authorization: "Bearer #{token}"}
      }.to change { Restaurant.count }.by(1)

      created_restaurant = Restaurant.last
      expect(created_restaurant.photo_urls.count).to eq 2
      expect(created_restaurant.user).to eq user
    end

    it 'returns created restaurant' do
      post '/restaurants', restaurant_json, {format: :json, authorization: "Bearer #{token}"}

      expect(json_response['name']).to eq "Tetsu"
      expect(json_response['address']).to eq "Roppongi"
      expect(json_response['cuisine_type']).to eq "Tonkatsu"
      expect(json_response['offers_english_menu']).to eq true
      expect(json_response['walk_ins_ok']).to eq true
      expect(json_response['accepts_credit_cards']).to eq true
      expect(json_response['notes']).to eq 'This restaurant has tasty バーニャカウダ'
    end
  end

  describe 'GET /restaurants/:id' do
    let!(:tsukemen) { Restaurant.create!(name: "Tukemen TETSU", created_at: 2.days.ago, user: user) }
    let(:user) { User.create!(name: 'Hachiko', password: 'password') }
    let(:token) { TokenEncoder.new(user).token }
    let!(:comment) { Comment.create!(content: "This is a comment", restaurant_id: tsukemen.id, user_id: user.id) }

    it 'returns the restaurant' do
      get "/restaurants/#{tsukemen.id}", {format: :json, authorization: "Bearer #{token}"}

      expect(json_response['name']).to eq 'Tukemen TETSU'
      expect(json_response['user']['name']).to eq 'Hachiko'
      expect(json_response['comments'][0]['content']).to eq 'This is a comment'
      expect(json_response['comments'][0]['user']['name']).to eq 'Hachiko'
    end
  end

  describe 'PATCH /restaurants/:id' do
    let!(:tsukemen) { Restaurant.create!(name: "Tukemen TETSU", created_at: 2.days.ago) }

    let(:restaurant_json) do
      {restaurant: {
          name: 'Renamed',
          address: 'Roppongi',
          cuisine_type: 'Tonkatsu',
          offers_english_menu: true,
          walk_ins_ok: true,
          accepts_credit_cards: true
      }}
    end

    it 'updates the restaurant' do
      patch "/restaurants/#{tsukemen.id}", restaurant_json, format: :json

      changed_restaurant = Restaurant.find(tsukemen.id)
      expect(changed_restaurant.name).to eq "Renamed"
    end
  end
end
