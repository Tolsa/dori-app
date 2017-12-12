class ProgramsController < ApplicationController

  def new
    @program = Program.new
  end

  def create
    @program = Program.new(program_params)
    @cards_builder = {}
    mapping= {
      "lundi" => "1_lundi",
      "mardi" => "2_mardi",
      "mercredi" => "3_mercredi",
      "jeudi" => "4_jeudi",
      "vendredi" => "5_vendredi",
      "samedi" => "6_samedi",
      "dimanche" => "7_dimanche"
    }
    params[:program][:cards_builder].reject(&:empty?).each do |day|
      @cards_builder[mapping[day]] = []
    end
    @program.cards_builder = @cards_builder
    @program.user = current_user
    @program.save
    redirect_to edit_program_path(@program)
  end




  def edit
    @program = Program.find(params[:id])
  end

  def update
    @program = Program.find(params[:id])
    @program.update(program_params)

    # @info = params[:program]
    # @info.each do |key, value|
    #   day = key.split('_').first
    #   @program.cards_builder[day] << {key.split('_').last.to_sym => value}
    # end

    @program.cards_builder.each do |key, value|
      if ["1_lundi","2_mardi","3_mercredi","4_jeudi","5_vendredi","6_samedi","7_dimanche"].include? key
        start_key = key + "_start"
        end_key = key + "_end"
        address_key = key + "_address"
        @program.cards_builder[key] = {}
        @program.cards_builder[key][:start] = params[:program][start_key]
        @program.cards_builder[key][:end] = params[:program][end_key]
        @program.cards_builder[key][:address] = params[:program][address_key]
        pool_card = Pool.near(@program.cards_builder[key][:address], 1.5)[0]
        @program.cards_builder[key][:okpool] = pool_card
        @trainings = Training.where(level: @program.swimming_level)
        training = @trainings.sample.description
        @program.cards_builder[key][:training] = training
      end
    end

    # pool_address.each do |pool|
    #   << pool[0]
    # end

    # i = 0
    # while i < address.length
    #   @pool_near = Pool.near(address[i], 0.7)
    #   i += 1
    # end
   #  @pool_near = Pool.near(address, 0.7)
    @program.save
    redirect_to program_cards_path(@program)
  end

  def send_to_google
    @program = Program.where(:user_id == current_user.id).last
    @google = GoogleCalendarWrapper.new(current_user)
    @google.send_calendar(@program)
    redirect_to root_path
  end


  private

  def program_params
    params.require(:program).permit(:swimming_level, cards_builder: {})
  end
end
