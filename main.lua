-- startrek roguelikelike experiment

function love.load()

	-- overhead starfield navigation demo

        -- set us up for blocky 3x3 pixel scaling of graphics
        love.graphics.setMode(960, 720, false, true, 0)
        love.graphics.setDefaultImageFilter("nearest", "nearest")

        -- load in some art assets!
        shipimage = love.graphics.newImage("/img/uss-ship.png")
	shipimage_half = love.graphics.newImage("/img/uss-ship_half.png")
	shipimage_quarter = love.graphics.newImage("/img/uss-ship_quarter.png")

	-- curious annoyance: must first load bitmap font as image to let imageFilter get set to nearest
	-- for it and THEN do newImageFont with that, or it will default to linear scaling after all
	bitmapfontimage = love.graphics.newImage("/font/tinybitmapfont.png")
	f_imgfont = love.graphics.newImageFont(bitmapfontimage,
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\\\"@$")

	font_default = f_imgfont

	planet_64 = love.graphics.newImage("/img/planet_64.png")
        planet_32 = love.graphics.newImage("/img/planet_32.png")
        planet_16 = love.graphics.newImage("/img/planet_16.png")
        planet_8  = love.graphics.newImage("/img/planet_8.png")
        planet_4  = love.graphics.newImage("/img/planet_4.png")


        -- create a simple ship table data structure
        ship = { image = shipimage, imagehalf = shipimage_half, imagequarter = shipimage_quarter, 
		x = 1000, y = 1000, theta = 0, velocity = 0, maxv = 100, minv = -30,
                xoffset = shipimage:getWidth() / 2, yoffset = shipimage:getHeight() / 2 }

        -- and let's generate a hacky starfield
	-- create a large field of random x,y coordinates
	starfield = {} 	
	for i=1, 1000 do
		local newstarx = math.random(0, 8000)
		local newstary = math.random(0, 8000)
		local newstarcolorr = math.random(100) + 155
		local newstarcolorg = math.random(100) + 155
		local newstarcolorb = math.random(50)  + 205
		table.insert(starfield, {newstarx, newstary, newstarcolorr, newstarcolorg, newstarcolorb} )
	end

	-- and a second field that we'll scroll in parallax!
        starfield_far = {}
        for i=1, 250 do
                local newstarx = math.random(0, 8000)
                local newstary = math.random(0, 8000)
                local newstarcolorr = math.random(100) + 55  -- farther stars dimmer!
                local newstarcolorg = math.random(100) + 55
                local newstarcolorb = math.random(50)  + 105
                table.insert(starfield_far, {newstarx, newstary, newstarcolorr, newstarcolorg, newstarcolorb} )
        end

	-- and how about a few planets while we're at it
	planetnames = {"Ceres", "Pallas", "Juno", "Vesta", "Astraea", "Hebe", "Iris", "Flora", "Metis", "Hygiea",
			"Parthenope", "Victoria", "Egeria", "Irene", "Eunomia", "Psyche", "Thetis", "Melpomene",
			"Fortuna", "Massalia", "Lutetia", "Kalliope", "Thalia", "Themis", "Phocaea"}
	planetmodifiers = {" I", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X", "-A", "-B", "-C", "-Z" } 
	planetfield = {}
	for i=1, 20 do
		local newplanetx = math.random(0,8000)
		local newplanety = math.random(0,8000)
		local newplanetcolorr = math.random(50) + 155
		local newplanetcolorg = math.random(50) + 155
		local newplanetcolorb = math.random(50) + 155
		
		local psize = math.random(3)
		local image, imagehalf, imagequarter, offset, offsethalf, offsetquarter
		if psize == 1 then
			image = planet_64 
			imagehalf = planet_32
			imagequarter = planet_16
			offset = 32	-- all these offset values are based on 64x64 source images
			offsethalf = 32 
			offsetquarter = 32
		elseif psize == 2 then
			image = planet_32 
			imagehalf = planet_16
			imagequarter = planet_8
                        offset = 32
                        offsethalf = 32
                        offsetquarter = 32
		else
			image = planet_16
			imagehalf = planet_8
			imagequarter = planet_4
                        offset = 32
                        offsethalf = 32
                        offsetquarter = 32
		end
		local pname = planetnames[i] .. planetmodifiers[math.random(#planetmodifiers)]
		table.insert(planetfield, 
			{x = newplanetx, y = newplanety, colorr = newplanetcolorr, colorg = newplanetcolorg,
				colorb = newplanetcolorb, image = image, imagehalf = imagehalf, imagequarter = imagequarter,
				offset = offset, offsethalf = offsethalf, offsetquarter = offsetquarter, name = pname }
			)
	end

	-- global camera zoom value for zooming in and out
	zoomlevel = 1
	-- global camera offset to put ship in center of screen
	-- currently rendering every object -- ships, stars, planets -- with explict adjustment
	--  via these offset, which seems pretty silly; drawing the stars once to a canvas
	--  would probably be a pretty smart alternative way to handle the situation ]]
	camx = 160
	camy = 120

end

function love.update(dt)
        -- handle turning
        if love.keyboard.isDown("left") then
                ship.theta = ship.theta - (60 * dt)
                if ship.theta < 0 then
                        ship.theta = ship.theta + 360
                end
        elseif love.keyboard.isDown("right") then
                ship.theta = ship.theta + (60 * dt)
                if ship.theta > 360 then
                        ship.theta = ship.theta - 360
                end
        end

        -- handle velocity changes
        if love.keyboard.isDown("up") then
                ship.velocity = ship.velocity + (1 * dt)
                if ship.velocity > ship.maxv then
                        ship.velocity = ship.maxv
                end
        elseif love.keyboard.isDown("down") then
                ship.velocity = ship.velocity - (1 * dt)
                if ship.velocity < ship.minv then
                        ship.velocity = ship.minv
                end
        end

        -- move ship in coordinate space based on heading and velocity
	ship.x = ship.x + (ship.velocity * math.cos(math.rad(ship.theta)))
        ship.y = ship.y + (ship.velocity * math.sin(math.rad(ship.theta)))
end

function love.draw()
	-- draw everything scaled up 3x for blocky pixel look
        love.graphics.scale(3, 3)

	-- draw the stars
	for i,v in ipairs(starfield_far) do
                love.graphics.setColor(v[3], v[4], v[5], 255)
                love.graphics.rectangle( "fill", ((v[1] - ship.x ) / (zoomlevel * 4)) + camx, ((v[2] - ship.y) / (zoomlevel * 4)) + camy, 1, 1 )
        end

	for i,v in ipairs(starfield) do
		love.graphics.setColor(v[3], v[4], v[5], 255)
		love.graphics.rectangle( "fill", ((v[1] - ship.x) / (zoomlevel * 2)) + camx, ((v[2] - ship.y) / (zoomlevel * 2)) + camy, 1, 1 )
	end

	-- draw the planets
	for i,v in ipairs(planetfield) do
		love.graphics.setColor(v.colorr, v.colorg, v.colorb, 255)
		if zoomlevel == 1 then
			love.graphics.draw(v.image, (v.x - ship.x) + camx, (v.y - ship.y) + camy, 0, 1, 1, v.offset, v.offset)
			love.graphics.printf( v.name, (v.x - ship.x) + camx, (v.y -ship.y) + camy + v.offset + 10, 0, "center")
		elseif zoomlevel == 2 then
                        love.graphics.draw(v.imagehalf, ((v.x - ship.x) / 2) + camx, ((v.y - ship.y) / 2) + camy, 0, 1, 1, v.offsethalf, v.offsethalf)
			love.graphics.printf( v.name, ((v.x - ship.x) / 2) + camx, ((v.y -ship.y) / 2) + camy + v.offset + 10, 0, "center")
		else
                        love.graphics.draw(v.imagequarter, ((v.x - ship.x) / 4) + camx, ((v.y - ship.y) / 4) + camy, 0, 1, 1, v.offsetquarter, v.offsetquarter)
			love.graphics.printf( v.name, ((v.x - ship.x) / 4) + camx, ((v.y -ship.y) / 4) + camy + v.offset + 10, 0, "center")
		end
	end

	-- draw the ship
        love.graphics.setColor(255,255,255,255)
	if zoomlevel == 1 then
        	love.graphics.draw(ship.image, camx, camy, math.rad(ship.theta), 1, 1, ship.xoffset, ship.yoffset)
	elseif zoomlevel == 2 then
                love.graphics.draw(ship.imagehalf, camx, camy, math.rad(ship.theta), 1, 1, ship.xoffset / 2, ship.yoffset / 2)
	else
                love.graphics.draw(ship.imagequarter, camx, camy, math.rad(ship.theta), 1, 1, ship.xoffset / 4, ship.yoffset / 4)
	end

	-- print a jolly message on the screen
        love.graphics.setFont(font_default)
        love.graphics.setColor(80, 80, 160)
        love.graphics.print( "arrow keys to move, z to zoom, esc to quit", 10, 218 )
end

function love.keypressed(key)
        if key == "down" then
        elseif key == "up" then
        elseif key == "right" then
        elseif key == "left" then
	elseif key == "z" then
		-- cycle through zoom levels in view
		if zoomlevel == 1 then
			zoomlevel = 2
		elseif zoomlevel == 2 then
			zoomlevel = 4
		else
			zoomlevel = 1
		end
	elseif key == "escape" then
		-- let's get out of here!
		love.event.quit()
        end
end
