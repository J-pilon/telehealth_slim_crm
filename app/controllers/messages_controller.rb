# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient
  before_action :set_message, only: %i[show edit update destroy]

  def index
    authorize Message
    @messages = policy_scope(@patient.messages.recent)
    @message = @patient.messages.build
  end

  def show
    authorize @message

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def new
    @message = @patient.messages.build
    authorize @message

    respond_to do |format|
      format.turbo_stream
      format.html do
        if turbo_frame_request?
          render :new, layout: false
        else
          redirect_to patient_messages_path(@patient)
        end
      end
    end
  end

  def edit
    authorize @message

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @message = @patient.messages.build(message_params)
    @message.user = current_user
    authorize @message

    respond_to do |format|
      format.turbo_stream
      if @message.save
        format.html { redirect_to patient_messages_path(@patient), notice: 'Message was successfully sent.' }
      else
        format.html do
          @messages = policy_scope(@patient.messages.recent)
          render :index, status: :unprocessable_content
        end
      end
    end
  end

  def update
    authorize @message

    respond_to do |format|
      format.turbo_stream
      if @message.update(message_params)
        format.html { redirect_to patient_messages_path(@patient), notice: 'Message was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @message
    @message.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to patient_messages_path(@patient), notice: 'Message was successfully deleted.' }
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:patient_id])
  end

  def set_message
    @message = @patient.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content, :message_type)
  end
end
