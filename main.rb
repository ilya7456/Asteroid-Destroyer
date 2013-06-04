#!/usr/bin/env ruby

require 'rubygems'
require 'gosu'

module ZOrder
    Player = 3
end

class Game < Gosu::Window
    
    def initialize
        super 800, 600, false
        self.caption = "Asteroid Destroyer"
        
        @back = Gosu::Image.new(self, "media/back.jpg", false)
        
        @player = Player.new(self)
        @player.warp(400, 300)
        
        @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
        
        start_game()
        
        $game_over = false
    end
    
    def start_game
        
        $bullets = []
        $asteroids = []
        $window = self
        
        $asteroids.push(Asteroid.new(self))
        $asteroids.push(Asteroid.new(self))
        
        $time = Time.now
        
    end
    
    def update
    unless $game_over
        if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then
            @player.turn_left
        end
        if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
            @player.turn_right
        end
        if button_down? Gosu::KbUp or button_down? Gosu::GpButton0 then
            @player.accelerate
        end
        if button_down? Gosu::KbSpace then 
            @player.attributes
            
            if Time.now - $time > 0.1 then
                $bullets.push(Bullet.new(@player.attributes[:x], @player.attributes[:y], @player.attributes[:angle], self))
            
                #puts "#{@player.attributes[:x]}, #{@player.attributes[:y]}, #{@player.attributes[:angle]}, #{@player.attributes[:vel_x]}, #{@player.attributes[:vel_y]}"
            
                $bullets.each do |b|
                    #puts b.attributes
                    b.shoot
                end
                
                $time = Time.now
            end
            
        end
        
        @player.move
        
        @player.hit?
        
        $bullets.each do |b|
            b.move
            if b.spent?
                $bullets.delete(b)
            end
        end
        
        $asteroids.each do |a|
            a.move
            if a.out?
                $asteroids.delete(a)
                $asteroids.push(Asteroid.new(self))
            end
        end
    
    end
    end
    
    def button_down(id)
        if id == Gosu::KbEscape
            close
        end
    end
    
    def draw
        
        @player.draw
        
        @back.draw(0, 0, 0)
        
        $bullets.each do |b|
            b.draw
        end
        
        $asteroids.each do |a|
            a.draw
        end
        
        if $game_over == false then
            @message = "    Score : #{@player.attributes[:score]}       Lives : #{@player.attributes[:lives]}   Asteroids : #{$asteroids.length}"
            @message_x = 10
            @message_y = 10
        elsif $game_over == true then
            @message = "GAME OVER"
            @message_x = 350
            @message_y = 200
        end
        
        @font.draw(@message, \
                   @message_x, @message_y, 4, 1.0, 1.0, 0xffffff00)
        
    end
end

class Player
    def initialize(window)
        @ship = Gosu::Image.new(window, "media/ship.png", false)
        
        @x = @y = @vel_x = @vel_y = @angle = 0
        
        @score = 0
        
        @lives = 3
        $level = 1
    end
    
    def warp(x,y)
        @x, @y = x, y
    end
    
    def level_up
        if $asteroids.length < 15 then
            $asteroids.push(Asteroid.new($window))
            $asteroids.push(Asteroid.new($window))
        else
            $level = 3
            $asteroids.push(Asteroid.new($window))
        end
    end
    
    def attributes
        { :x => @x, :y => @y, :vel_x => @vel_x, :vel_y => @vel_y, :angle => @angle, :score => @score, :lives => @lives }
    end
    
    def hit?
        $asteroids.each do |a|
            $bullets.each do |b|
                if b.attributes[:x] > a.attributes[:x] and b.attributes[:x] < a.attributes[:border_x] then
                    if b.attributes[:y] > a.attributes[:y] and b.attributes[:y] < a.attributes[:border_y] then
                        $asteroids.delete(a)
                        $bullets.delete(b)
                        @score += 10
                        #puts @score
                        if @score % 50 == 0
                            level_up
                        else
                            $asteroids.push(Asteroid.new($window))
                        end
                        
                        
                    end
                end
            end
            
            if a.attributes[:x] <= @x and a.attributes[:border_x] >= @x and a.attributes[:y] <= @y and a.attributes[:border_y] >= @y
                #puts "Game Over"
                @lives -= 1
                if @lives == 0
                    $game_over = true
                else
                    sleep(1)
                    $game.start_game
                end
            end
            
        end
    end
    
    def turn_left
        @angle -= 3.0
    end
    
    def turn_right
        @angle += 3.0
    end
    
    def accelerate
        @vel_x += Gosu::offset_x(@angle, 0.8)
        @vel_y += Gosu::offset_y(@angle, 0.8)
    end
    
    def move
        @x += @vel_x
        @y += @vel_y
        @x %= 800
        @y %= 600
        
        @vel_x *= 0.85
        @vel_y *= 0.85
    end
    
    def draw
        @ship.draw_rot(@x, @y, ZOrder::Player, @angle)
    end
end

class Bullet
    def initialize(x,y,angle,window)
        @bullet = Gosu::Image.new(window, "media/bullet.png", false)
        
        @x, @y, @angle = x, y, angle
        @vel_x = @vel_y = 0
        @shot = false
    end
    
    def attributes
        { :x => @x, :y => @y, :vel_x => @vel_x, :vel_y => @vel_y, :angle => @angle }
    end
    
    def spent?
        (@x < 0 or @x > 800) or (@y < 0 or @y > 600)
    end
    
    def shoot
       unless @shot
           @shot = true
           @vel_x += (Gosu::offset_x(@angle, 1))*10
           @vel_y += (Gosu::offset_y(@angle, 1))*10
       end
    end
    
    def move
        @x += @vel_x unless spent?
        @y += @vel_y unless spent?
    end
    
    def draw
        @bullet.draw_rot(@x, @y, 1, @angle)
    end
end

class Asteroid
    def initialize(window)
        @asteroid = Gosu::Image.new(window, "media/asteroid.png", false)
        
        @vel_x = rand(4) + $level
        @vel_y = rand(4) + $level
        @angle = rand(360)
        @vel_ang = rand(10)
        
        i = rand(2)
        j = rand(2)
        #puts "#{i} #{j}"
        
        if i == 0 then
            @y = rand(600)
            if j == 0 then
                @x = 0
            elsif j == 1 then
                @x = 800
                @vel_x = @vel_x * -1
            end
        elsif i == 1 then
            @x = rand(800)
            if j == 0 then
                @y = 0
            elsif j == 1 then
                @y = 600
                @vel_y = @vel_y * -1
            end
        end
    end
    
    def attributes
        { :x => @x - 25, :y => @y - 25, :border_x => @x + 25, :border_y => @y + 25, :angle => @angle }
    end
    
    
    def out?
        (@x < 0 or @x > 800) or (@y < 0 or @y > 600)
    end
    
    def draw
        @asteroid.draw_rot(@x, @y, 1, @angle)
    end
    
    def move
        @x += @vel_x unless out?
        @y += @vel_y unless out?
        @angle += @vel_ang unless out?
    end
end

$game = Game.new
$game.show