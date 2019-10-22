local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local pi = math.pi
local random = love.math.random
local rshift = bit.rshift
local sqrt = math.sqrt

function splitByte(byte)
  local upperHalf = rshift(band(byte, 0xf0), 4)
  local lowerHalf = band(byte, 0xf)

  return upperHalf, lowerHalf
end

function joinByte(upperHalf, lowerHalf)
  upperHalf = band(upperHalf, 0xf)
  lowerHalf = band(lowerHalf, 0xf)

  return bor(lshift(upperHalf, 4), lowerHalf)
end

function loadScene(filename)
  local success, result = pcall(dofile, targetFilename)

  if success then
    result.brush = result.brush or "circle"
  end

  return success, result
end

function saveScene(scene, filename)
  local file = io.open(filename, "w")
  file:write("return {\n")
  file:write("  brush = \"" .. scene.brush .. "\",\n")
  file:write("\n")
  file:write("  layers = {\n")

  for i, layer in ipairs(scene.layers) do
    file:write("    {" .. table.concat(layer, ", ") .. "},\n")
  end

  file:write("  },\n")
  file:write("}\n")
  file:close()
end

function cloneScene(scene)
  local layers = {}

  for i, layer in ipairs(scene.layers) do
    layers[i] = {unpack(layer)}
  end

  return {
    brush = scene.brush,
    layers = layers,
  }
end

function generateBoolean()
  return random(0, 1) == 1
end

function generateByte()
  return random(0, 255)
end

function generateSize()
  local size = lshift(1, random(0, 7))
  local mask = size - 1
  local jitter = band(generateByte(), mask)
  return bor(size, jitter)
end

function generateLayer(brush)
  if brush == "circle" then
    local x = generateByte()
    local y = generateByte()

    local size = generateSize()

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {x, y, size, redGreen, blueAlpha}
  elseif brush == "square" then
    local x = generateByte()
    local y = generateByte()

    local angle = generateByte()
    local size = generateSize()

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {x, y, angle, size, redGreen, blueAlpha}
  else
    assert(false)
  end
end

function generateScene(brush, size)
  local layers = {}

  for i = 1, size do
    layers[i] = generateLayer(brush)
  end

  return {
    brush = brush,
    layers = layers,
  }
end

function mutateLayer(layer)
  local i = random(1, #layer)

  local upperHalf, lowerHalf = splitByte(layer[i])

  if generateBoolean() then
    upperHalf = generateByte()
  else
    lowerHalf = generateByte()
  end

  layer[i] = joinByte(upperHalf, lowerHalf)
end

function mutateScene(scene)
  if generateBoolean() then
    -- Replace layer
    local i = random(1, #scene.layers)
    local j = random(1, #scene.layers)
    local layer = generateLayer(scene.brush)
    table.remove(scene.layers, i)
    table.insert(scene.layers, j, layer)
  else
    -- Mutate layer
    local i = random(1, #scene.layers)
    mutateLayer(scene.layers[i])
  end
end

function love.load(arg)
  if #arg ~= 3 or arg[1] ~= "evolve" then
    print("Usage: love . evolve <source> <target>")
    love.event.quit(1)
    return
  end

  _, sourceFilename, targetFilename = unpack(arg)

  love.window.setTitle("Lima")
  love.window.setMode(1024, 512)
  referenceImageData = love.image.newImageData(sourceFilename)
  referenceImage = love.graphics.newImage(referenceImageData)

  print("Loading...")
  local success, result = loadScene(targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generateScene("square", 256)
  end
end

local function drawSceneToCanvas(scene, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  local width, height = canvas:getDimensions()
  love.graphics.scale(width, height)

  if scene.brush == "circle" then
    for i, layer in ipairs(scene.layers) do
      local x, y, size, redGreen, blueAlpha = unpack(layer)

      local red, green = splitByte(redGreen)
      local blue, alpha = splitByte(blueAlpha)

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)
      love.graphics.circle("fill", x / 255, y / 255, 0.5 * size / 255)
    end
  elseif scene.brush == "square" then
    for i, layer in ipairs(scene.layers) do
      local x, y, angle, size, redGreen, blueAlpha = unpack(layer)

      local red, green = splitByte(redGreen)
      local blue, alpha = splitByte(blueAlpha)

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)

      love.graphics.push()
      love.graphics.rotate(2 * pi * angle / 256)

      love.graphics.rectangle(
        "fill",
        x / 255 - 0.5 * size / 255,
        y / 255 - 0.5 * size / 255,
        size / 255,
        size / 255)

      love.graphics.pop()
    end
  end

  love.graphics.setCanvas()
end

local function rms4(x, y, z, w)
  return sqrt(0.25 * (x * x + y * y + z * z + w * w))
end

local function getDistance(image1, image2)
  local width1, height1 = image1:getDimensions()
  local width2, height2 = image2:getDimensions()
  assert(width1 == width2 and height1 == height2)

  local totalDistance = 0

  for y = 0, height1 - 1 do
    for x = 0, width1 - 1 do
      local r1, g1, b1, a1 = image1:getPixel(x, y)
      local r2, g2, b2, a2 = image2:getPixel(x, y)

      local distance = rms4(r2 - r1, g2 - g1, b2 - b1, a2 - a1)
      totalDistance = totalDistance + distance
    end
  end

  return totalDistance / (width1 * height1)
end

function love.draw()
  if not canvas then
    canvas = love.graphics.newCanvas(512, 512)
    drawSceneToCanvas(parent, canvas)
    local parentImageData = canvas:newImageData()
    parentFitness = getDistance(parentImageData, referenceImageData)
    parentImage = love.graphics.newImage(parentImageData)
    print("Fitness: " .. parentFitness)
  end

  love.graphics.reset()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(referenceImage, 0, 0)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(parentImage, 512, 0)

  local child = cloneScene(parent)
  mutateScene(child)

  drawSceneToCanvas(child, canvas)
  local childImageData = canvas:newImageData()
  local childFitness = getDistance(childImageData, referenceImageData)

  if childFitness < parentFitness then
    parent = child
    parentFitness = childFitness
    parentImage = love.graphics.newImage(childImageData)

    print("Fitness: " .. parentFitness)
    saveScene(parent, targetFilename)
  end
end

function love.quit()
  if parent and targetFilename then
    print("Saving...")
    saveScene(parent, targetFilename)
  end
end
