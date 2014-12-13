local Raycaster = oohelper.newClass({
	new = function(self, mapWidth, mapHeight)
		self.tiles = {}

		for y=1,mapHeight do
			self.tiles[y] = {}
			for x=1,mapWidth do
				self.tiles[y][x] = 0
			end
		end
	end
})