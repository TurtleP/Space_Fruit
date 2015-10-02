function newShip(x, y, hp)
	local ship = {}

	ship.x = x
	ship.y = y
	ship.hp = hp
	ship.rotation = 0
	ship.width = 40
	ship.height = 40
	ship.quad = quads["ship"]
	ship.quadi = 1
	ship.animtimer = 0
	ship.shouldrotate = false
	ship.speedy = 0
	ship.speedx = 0
	ship.shouldMove = false 
	ship.invincible = false
	ship.invincibletimer = 0
	ship.drawable = true 
	ship.hud = newHud(hp)
	ship.hits = 1

	ship.rotationright = false
	ship.rotationleft = false

	function ship:draw()
		if self.drawable then
			love.graphics.draw(graphics["ship"], self.quad[self.quadi][self.hits], self.x + 20, self.y + 20, self.rotation, 1, 1, self.width / 2, self.height / 2)
		end

		self.hud:draw(self.hp)
	end

	function ship:shoot()
		game_playsound(shoot[love.math.random(#shoot)])
		table.insert(objects.bullet, newBullet(self.x + (self.width / 2) - 0.5, self.y + (self.height / 2) - 3, self.rotation, self))
	end

	function ship:update(dt)
		if self.rotationright then
			self.rotation = self.rotation + 4 * dt
		elseif self.rotationleft then
			self.rotation = self.rotation - 4 * dt 
		end

		if self.rotationright or self.rotationleft or self.moveForth then
			self.animtimer = self.animtimer + 8 * dt
			self.quadi = math.floor(self.animtimer%3)+2
		elseif not self.rotationleft and not self.rotationright and not self.moveForth then
			self.animtimer = 0
			self.quadi = 1
		end

		if self.shouldMove then
			if self.moveForth then
				self.speedy = -math.cos(self.rotation) * 2
				self.speedx = math.sin(self.rotation) * 2
			end
		end

		if self.speedy > 0 then
			self.speedy = math.max(self.speedy - 2 * dt, 0)
		else
			self.speedy = math.min(self.speedy + 2 * dt, 0)
		end

		if self.speedx > 0 then
			self.speedx = math.max(self.speedx - 2 * dt, 0)
		else
			self.speedx = math.min(self.speedx + 2 * dt, 0)
		end

		self:checkWarp()

		self.y = self.y + self.speedy
		self.x = self.x + self.speedx

		if self.invincible then
			self.invincibletimer = self.invincibletimer + 6 * dt 

			if math.floor(self.invincibletimer%2) == 0 then
				self.drawable = false 
			else
				self.drawable = true
			end

			if self.invincibletimer > 19 then
				self.invincibletimer = 0
				self.invincible = false
			end
		end

		self.hud:update(dt)
	end

	function ship:moveForward()
		self.moveForth = true
		self.shouldMove = true
	end

	function ship:rotateAdd(add)
		if add then
			self.rotationright = true
		else
			self.rotationleft = true
		end
	end

	function ship:move(key)
		print(controls[4])
		if key == controls[4] then
			print("!")
			self:shoot()
		end

		if key == controls[1] then
			self:rotateAdd(true)
		elseif key == controls[2] then
			self:rotateAdd(false)
		end

		if key == controls[3] then
			self:moveForward()
		end

		if key == controls[5] then
			self:addShield()
		end
	end

	function ship:addShield()
		if self.hud.shieldbar == self.hud.shieldbarmax then
			table.insert(objects["powerup"], newShield(self))
			self.hud.shieldActive = true
		end
	end

	function ship:stopMove(key)
		if key == controls[2] then
			self.rotationleft = false
		end

		if key == controls[1] then
			self.rotationright = false
		end

		if key == controls[3] then
			self.moveForth = false
			self.shouldMove = false
		end
	end

	function ship:joystickAxis(joystick, axis, value)
		if joystick == game_joystick then
			if axis == 1 then
				if value > 0.2 then
					self.rotationright = true
				elseif value < 0.2 and value >= 0 then
					self.rotationright = false
				end
			end

			if axis == 1 then
				if value < -0.2 then
					self.rotationleft = true
				elseif value > -0.2 and value <= 0 then
					self.rotationleft = false
				end
			end

			if axis == 2 then
				if value < -0.2 then
					self:moveForward()
				elseif value > -0.2 and value <= 0 then
					self.moveForth = false
					self.shouldMove = false
				end
			end
		end
	end

	function ship:gamePad(button)
		if button == "a" or button == "x" then
			self:shoot()
		end

		if button == "y" or button == "b" then
			self:addShield()
		end
	end

	function ship:checkWarp()
		local ww = love.window.getWidth() / scale
		local wh = love.window.getHeight() / scale

		if self.x + self.width > ww then
			self.x = 0

			game_randomStaticPlanet()

		elseif self.y + self.height > wh then
			self.y = 0
			
			game_randomStaticPlanet()
		elseif self.x < 0 then
			self.x = ww - 40

			game_randomStaticPlanet()
		elseif self.y < 0 then
			self.y = wh - 40

			game_randomStaticPlanet()
		end
	end

	function ship:addLife(lifeAmount)
		if not self.invincible then
			self.hp = math.max(self.hp + lifeAmount, 0)

			if self.hp == 0 then
				gameover = true
				game_playsound(gameoversnd)
				self.drawable = false
			--	gameoversong = love.audio.newSource("sound/title.ogg", "stream")
			--	gameoversong:setLooping(true)
				

				return
			end

			if lifeAmount < 0 then
				if not self.hud.shieldActive then
					game_playsound(damage[love.math.random(#damage)])

					self.hits = math.min(self.hits + 1, 4)
					self.invincible = true
				end
			else
				self.hits = math.max(self.hits - 1, 1)
			end
		end
	end

	function ship:onCollide(name, data)
		if name == "powerup" then
			if data.quadi == 2 then
				self:addLife(1)
				data.remove = true
			end
		end
	end

	return ship
end