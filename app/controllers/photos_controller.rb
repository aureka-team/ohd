class PhotosController < ApplicationController
  require 'open-uri'

  def create
    authorize Photo
    data = params[:photo].delete(:data)
    @photo = Photo.create(photo_params)
    @photo.photo.attach(io: data, filename: "#{@photo.interview.archive_id.upcase}_#{str = format('%02d', @photo.interview.photos.count)}", metadata: {title: photo_params[:caption]})
    write_iptc_metadata

    respond_to do |format|
      format.json do
        render json: {
          data_type: 'interviews',
          id: @photo.interview.archive_id,
          nested_data_type: 'photos',
          nested_id: @photo.id,
          data: ::PhotoSerializer.new(@photo).as_json
        }
      end
    end
  end

  def update
    @photo = Photo.find(params[:id])
    authorize @photo
    @photo.update_attributes(photo_params)
    write_iptc_metadata

    respond_to do |format|
      format.json do
        render json: {
          data_type: 'interviews',
          id: @photo.interview.archive_id,
          nested_data_type: 'photos',
          nested_id: @photo.id,
          data: ::PhotoSerializer.new(@photo).as_json
        }
      end
    end
  end

  def destroy
    @photo = Photo.find(params[:id])
    authorize @photo
    @photo.destroy
    clear_cache @photo.interview

    respond_to do |format|
      format.html do
        render :action => 'index'
      end
      format.json { render json: {}, status: :ok }
    end
  end

  def src
    deliver "original/#{sub_folder(params[:name])}/#{params[:name]}.jpg"
  end

  def thumb
    deliver "1.5MB/#{sub_folder(params[:name])}/#{params[:name]}.jpg"
  end

  private

  def photo_params
    params.require(:photo).permit(
      :interview_id,
      :public_id,
      :workflow_state,
      translations_attributes: [:locale, :id, :caption, :place, :date, :photographer, :license]
    )
  end

  def deliver file_name
    base_url = 'http://dedalo.cedis.fu-berlin.de/dedalo/media/image/'
    url = base_url + file_name
    data = open(url).read
    send_data data, :disposition => 'inline', :filename=>file_name
  end

  def sub_folder image_name
    ((image_name.split('_').last().to_i / 1000) * 1000).to_s;
  end

  def write_iptc_metadata
    # we can write only one language version as IPTC
    #
    translation_params = photo_params[:translations_attributes].first
    date = Date.parse(translation_params[:date]).strftime("%Y%m%d") rescue translation_params[:date]

    WriteImageIptcMetadataJob.perform_later(@photo.id, {
      caption: translation_params[:caption],
      creator: translation_params[:photographer],
      headline: "#{@photo.interview.archive_id}-Interview mit #{@photo.interview.short_title(locale)}",
      copyright: translation_params[:license],
      date: date,
      city: translation_params[:place]
    })
  end

end
