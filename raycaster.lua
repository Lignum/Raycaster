local BASE_16 = "0123456789abcdef"

--# Linearly interpolates x and y by t.
local function lerp(x, y, t)
	return (1 - t) * x + t * y
end

--# Calculates c from a and b.
local function hypot(a, b)
	--# c^2=a^2+b^2
	--# c=sqrt(a^2+b^2)
	return math.sqrt(a^2+b^2)
end

local Raycaster = oohelper.newClass({
	new = function(self, mapWidth, mapHeight)
		self:clearTiles()

		self.width = mapWidth
		self.height = mapHeight

		self.cameraX = 0
		self.cameraY = 0
		self.cameraAngle = 0
		self.cameraFov = 90

		for y=1,mapHeight do
			self.tiles[y] = {}
			for x=1,mapWidth do
				self.tiles[y][x] = 0
			end
		end
	end,

	setCameraTransform = function(self, x, y, angle)
		self.cameraX = x
		self.cameraY = y
		self.cameraAngle = angle
	end,

	setCameraFOV = function(self, fov)
		self.cameraFov = fov
	end,

	getCameraTransform = function(self)
		return self.cameraX, self.cameraY, self.cameraAngle
	end,

	setTile = function(self, x, y, tile)
		self.tiles[y][x] = tile
	end,

	getTile = function(self, x, y)
		assert(x and y)

		x = math.floor(x)
		y = math.floor(y)

		if x > self.width or y > self.height or x < 1 or y < 1 then
			return 0
		end

		return self.tiles[y][x]
	end,

	clearTiles = function(self)
		self.tiles = {}
	end,

	loadFromFile = function(self, file)
		local f = assert(fs.open(file, "r"), "failed to open file " .. file)

		self:clearTiles()

		local line = f.readLine()
		local y = 1
		while line ~= nil do
			--# Create a new row at the current position.
			self.tiles[y] = {}

			for x=1,#line do --# For every character in the line...
				local c = line:sub(x, x) --# Gets the current character.
				local i = BASE_16:find(c) --# Convert hex to decimal.
				if i ~= nil then
					self.tiles[y][x] = i --# Insert the tile into the row.
				else
					self.tiles[y][x] = 0 --# If i is nil, there is no tile.
				end
			end

			self.width = #line

			y = y + 1
			line = f.readLine()
		end

		self.height = y - 1

		f.close()
	end,

	getWidth = function(self)
		return self.width
	end,

	getHeight = function(self)
		return self.height
	end,

	getSize = function(self)
		return self.width,self.height
	end,

	--# Casts a ray from a specified position at an angle with a specified maximum length.
	--# Returns the tile it hit aswell as the distance the ray travelled.
	castRay = function(self, angle, length)
		local x = self.cameraX
		local y = self.cameraY

		--# Compute the target position so that we can interpolate to it.
		local targetX = x + math.cos(math.rad(angle)) * length
		local targetY = y + math.sin(math.rad(angle)) * length

		--# Calculate the distance between the start and target,
		--# so that we can get the increase for the for loop.
		local dist = hypot(targetX - x, targetY - y)
		local increase = 1/dist

		for t=0,1,increase do
			--# Get the next position on the line between the start position and target position.
			local nextX = lerp(x, targetX, t)
			local nextY = lerp(y, targetY, t)

			local nextTile = self:getTile(nextX, nextY)

			if nextTile > 0 then --# We've hit a tile.
				return nextTile, hypot(nextX - x, nextY - y)
			end
		end

		return 16, 0
	end,

	--# For debugging.
	draw2D = function(self, surface)
		local surf = surface or term
		local w,h = surf.getSize()

		for y=1,self.height do
			for x=1,self.width do
				local i = self:getTile(x, y)

				if i > 0 then
					local col = 2 ^ (i - 1)
					surf.setCursorPos(x, y)
					surf.setBackgroundColour(col)
					surf.write(" ")
				end
			end
		end

		for i=1,w do
			local t = i/w
			local angle = lerp(self.cameraAngle - self.cameraFov / 2, self.cameraAngle + self.cameraFov / 2, t)
			paintutils.drawLine(self.cameraX, self.cameraY, self.cameraX+math.cos(math.rad(angle))*3, self.cameraY+math.sin(math.rad(angle))*3, colours.yellow)
		end
	end,

	draw3D = function(self, surface)
		local ok, err = pcall(function()
			local surf = surface or term
			local w,h = surf.getSize()
			drawDist = h

			for i=1,w do
				local t = i/w
				local angle = lerp(self.cameraAngle - self.cameraFov / 2, self.cameraAngle + self.cameraFov / 2, t)

				local tile, dist = self:castRay(angle, drawDist)
				local depth = dist
				local wallHeight = depth

				if wallHeight <= h then
					for j=1,wallHeight do
						surf.setCursorPos(i, j + h / 2 - wallHeight / 2)
						surf.setBackgroundColour(2 ^ (tile - 1))
						surf.write(" ")
						surf.setCursorPos(1, 1)
					end
				end
			end
		end)

		if not ok then
			term.setBackgroundColour(colours.black)
			term.clear()
			term.setCursorPos(1, 1)
			term.setTextColour(colours.white)
			print(err)
		end
	end
})

return Raycaster