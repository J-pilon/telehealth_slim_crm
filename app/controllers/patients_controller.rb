# frozen_string_literal: true

class PatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient, only: [:show, :edit, :update, :destroy]

  def index
    authorize Patient
    @patients = policy_scope(Patient)
    @patients = @patients.active if params[:status] == 'active'
    @patients = @patients.inactive if params[:status] == 'inactive'
    @patients = @patients.by_name if params[:sort] == 'name'
    @patients = @patients.recent if params[:sort] == 'recent'
    @patients = @patients.page(params[:page]).per(20)
  end

  def show
    authorize @patient
    @recent_messages = @patient.messages.recent.limit(10)
    @pending_tasks = @patient.tasks.pending.limit(10)
    @completed_tasks = @patient.tasks.completed.limit(5)
  end

  def new
    @patient = Patient.new
    authorize @patient
  end

  def create
    @patient = Patient.new(patient_params)
    authorize @patient

    if @patient.save
      redirect_to @patient, notice: 'Patient was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @patient
  end

  def update
    authorize @patient

    if @patient.update(patient_params)
      redirect_to @patient, notice: 'Patient was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @patient
    @patient.destroy
    redirect_to patients_path, notice: 'Patient was successfully deleted.'
  end

  def search
    authorize Patient
    query = params[:q]

    if query.present?
      @patients = Patient.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR medical_record_number ILIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
      ).limit(10)
    else
      @patients = []
    end

    respond_to do |format|
      format.json { render json: @patients.map { |p| { id: p.id, full_name: p.full_name, email: p.email, medical_record_number: p.medical_record_number, status: p.status } } }
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(:first_name, :last_name, :email, :phone,
                                   :date_of_birth, :medical_record_number, :status)
  end
end
