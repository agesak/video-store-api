class RentalsController < ApplicationController

  def checkout
    rental = Rental.new(rental_params)
    rental.assign_attributes(due_date: (Time.now + 7.days).strftime("%Y-%m-%d"))
    if rental.valid? && rental.customer.update_video_count
      if rental.video.checkout
        rental.save
        rental_info = rental.as_json(
          only: [:customer_id, :video_id, :due_date]).merge(
          videos_checked_out_count: rental.customer.videos_checked_out_count,
          available_inventory: rental.video.available_inventory
          )
        render json: rental_info, status: :ok
      else
        render json: {ok: false, errors: rental.video.errors.messages}, status: :bad_request
      end
    else
      render json: {errors: ['Not Found']}, status: :not_found
    end
  end

  def checkin

    rental = Rental.find_by(rental_params)

    video  = Video.find_by(id: params[:video_id])

    customer = Customer.find_by(id: params[:customer_id])

    render json: {errors: ['Not Found']}, status: :not_found and return if customer.nil? || video.nil? || rental.nil?

    render json: {ok: false, errors: customer.errors.messages}, status: :bad_request and return unless customer.decrease_video_count

    render json: {ok: false, errors: video.errors.messages}, status: :bad_request  and return unless video.checkin

    rental_info = {
        customer_id: customer.id,
        video_id: video.id,
        videos_checked_out_count: customer.videos_checked_out_count,
        available_inventory: video.available_inventory
    }

    rental.destroy

    render json: rental_info, status: :ok
  end

  private

  def rental_params
    params.permit(:customer_id, :video_id)
  end
end
