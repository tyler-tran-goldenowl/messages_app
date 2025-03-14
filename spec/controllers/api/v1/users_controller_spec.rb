require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            first_name: 'John',
            last_name: 'Doe',
            birthdate: '1990-01-01',
            location: 'New York'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'returns a 201 status code' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created user as JSON' do
        post :create, params: valid_params
        expect(JSON.parse(response.body)['first_name']).to eq('John')
        expect(JSON.parse(response.body)['last_name']).to eq('Doe')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            first_name: '',
            last_name: 'Doe',
            birthdate: '1990-01-01',
            location: 'New York',
            timezone: 'America/New_York'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'returns a 422 status code' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the errors as JSON' do
        post :create, params: invalid_params
        expect(JSON.parse(response.body)['errors']).to include("First name can't be blank")
      end
    end
  end

  describe 'PUT #update' do
    let!(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    context 'with valid parameters' do
      let(:valid_params) do
        {
          id: user.id,
          user: {
            first_name: 'Jane',
            last_name: 'Smith'
          }
        }
      end

      it 'updates the user' do
        put :update, params: valid_params
        user.reload
        expect(user.first_name).to eq('Jane')
        expect(user.last_name).to eq('Smith')
      end

      it 'returns a 200 status code' do
        put :update, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated user as JSON' do
        put :update, params: valid_params
        expect(JSON.parse(response.body)['first_name']).to eq('Jane')
        expect(JSON.parse(response.body)['last_name']).to eq('Smith')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          id: user.id,
          user: {
            first_name: '',
            last_name: 'Smith'
          }
        }
      end

      it 'does not update the user' do
        put :update, params: invalid_params
        user.reload
        expect(user.first_name).to eq('John')
      end

      it 'returns a 422 status code' do
        put :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the errors as JSON' do
        put :update, params: invalid_params
        expect(JSON.parse(response.body)['errors']).to include("First name can't be blank")
      end
    end

    context 'with non-existent user' do
      it 'returns a 404 status code' do
        put :update, params: { id: 999, user: { first_name: 'Jane' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user) { create(:user) }

    it 'deletes the user' do
      expect {
        delete :destroy, params: { id: user.id }
      }.to change(User, :count).by(-1)
    end

    it 'returns a 204 status code' do
      delete :destroy, params: { id: user.id }
      expect(response).to have_http_status(:no_content)
    end

    context 'with non-existent user' do
      it 'returns a 404 status code' do
        delete :destroy, params: { id: 999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
